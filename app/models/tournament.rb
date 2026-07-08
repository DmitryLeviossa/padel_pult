# == Schema Information
#
# Table name: tournaments
#
#  id               :bigint           not null, primary key
#  description      :text
#  end_date         :datetime         not null
#  groups_count     :integer
#  loser_bracket    :boolean          default(FALSE), not null
#  max_participants :integer          default(16), not null
#  name             :string           not null
#  pairs_to_bracket :integer
#  placement_points :jsonb            not null
#  ranking_method   :string           default("score_delta"), not null
#  rounds_count     :integer
#  start_date       :datetime         not null
#  status           :string           default("draft"), not null
#  type             :string           default("olympic"), not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  club_id          :bigint
#  league_id        :bigint           not null
#
# Indexes
#
#  index_tournaments_on_club_id    (club_id)
#  index_tournaments_on_league_id  (league_id)
#
# Foreign Keys
#
#  fk_rails_...  (club_id => clubs.id)
#  fk_rails_...  (league_id => leagues.id)
#
class Tournament < ApplicationRecord
  self.inheritance_column = nil

  belongs_to :league
  belongs_to :club, optional: true
  has_many :brackets, dependent: :destroy
  has_many :matches, dependent: :destroy
  has_many :pairs, dependent: :destroy
  has_many :tournament_participants, dependent: :destroy

  enum :status, { draft: "draft", registration: "registration", active: "active", completed: "completed", cancelled: "cancelled" }
  enum :type, { olympic: "olympic", round_robin: "round_robin", mixed: "mixed", americano: "americano" }
  enum :ranking_method, { score_delta: "score_delta", by_wins: "by_wins" }

  validates :start_date, presence: true
  validates :end_date, presence: true
  validates :groups_count, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :pairs_to_bracket, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :rounds_count, numericality: { only_integer: true, greater_than: 0 }, if: :americano?
  validate :end_date_not_before_start_date
  validate :placement_points_valid
  validate :mixed_config_present, if: :mixed?
  validate :pairs_to_bracket_valid_for_groups, if: :mixed?
  validate :league_quota_available, on: :create

  after_create :decrement_league_quota
  after_create :generate_match_structure
  after_update :regenerate_match_structure, if: :structure_params_changed?

  def all_matches_completed?
    real = matches.where.not(pair1_id: nil, pair2_id: nil)
    real.any? && !real.pending.exists?
  end

  def max_pairs
    max_participants / 2
  end

  def points_for_place(position)
    Array(placement_points).each do |rule|
      from = rule["from"].to_i
      to   = rule["to"].to_i
      return rule["points"].to_i if position >= from && position <= to
    end
    0
  end

  def bracket_slot_labels
    return {} unless pairs_to_bracket && groups_count

    total = pairs_to_bracket * groups_count
    return {} if total < 4

    n = 2**Math.log2(total).ceil
    ru = %w[А Б В Г Д Е Ж З И К Л М Н О П Р С Т У Ф Х Ц Ч Ш Щ Э Ю Я]
    sf1 = []
    sf2 = []
    groups_count.times do |g_idx|
      pairs_to_bracket.times do |rank_idx|
        label = "#{ru[g_idx]}#{rank_idx + 1}"
        ((g_idx + rank_idx).even? ? sf1 : sf2) << label
      end
    end

    slots = Array.new(n, nil)
    fill = ->(labels, indices) {
      half = indices.length / 2
      labels.each_with_index do |label, i|
        idx = i < half ? indices[i] : indices[indices.length - 1 - (i - half)]
        slots[idx] = label if idx
      end
    }
    fill.(sf1, (0...n / 4).to_a + (3 * n / 4...n).to_a.reverse)
    fill.(sf2, (n / 4...n / 2).to_a + (n / 2...3 * n / 4).to_a.reverse)

    (n / 2).times.each_with_object({}) do |i, map|
      map[i + 1] = { pair1: slots[i], pair2: slots[n - 1 - i] }
    end
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[name status type start_date end_date club_id]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[club]
  end

  private

  def league_quota_available
    return unless league&.tournaments_quota
    errors.add(:base, "квота на создание турниров в этой лиге исчерпана") if league.tournaments_quota <= 0
  end

  def decrement_league_quota
    league.decrement!(:tournaments_quota) if league.tournaments_quota&.positive?
  end

  def generate_match_structure
    Tournaments::Matches::StructureGenerator.new(self).call
  end

  def regenerate_match_structure
    Tournaments::Matches::StructureGenerator.new(self).call
  end

  def structure_params_changed?
    saved_changes.keys.any? { |k| %w[max_participants type groups_count pairs_to_bracket loser_bracket].include?(k) }
  end

  def mixed_config_present
    errors.add(:groups_count, :blank) if groups_count.blank?
    errors.add(:pairs_to_bracket, :blank) if pairs_to_bracket.blank?
  end

  def pairs_to_bracket_valid_for_groups
    return unless pairs_to_bracket && groups_count&.positive?
    total = pairs_to_bracket * groups_count
    if total > max_pairs
      errors.add(:pairs_to_bracket, "слишком много: #{total} пар не помещается в #{max_pairs} (#{pairs_to_bracket} × #{groups_count} групп)")
    end
  end

  def end_date_not_before_start_date
    return unless start_date && end_date
    errors.add(:end_date, "не может быть раньше даты начала") if end_date < start_date
  end

  def placement_points_valid
    rules = Array(placement_points)
    rules.each_with_index do |rule, i|
      from   = rule["from"].to_i
      to     = rule["to"].to_i
      points = rule["points"].to_i

      if from < 1 || to < 1
        errors.add(:placement_points, "rule #{i + 1}: place must be >= 1")
        next
      end

      if from > to
        errors.add(:placement_points, "rule #{i + 1}: 'from' must be <= 'to'")
        next
      end

      errors.add(:placement_points, "rule #{i + 1}: points must be > 0") if points < 1
    end

    # Check for overlapping ranges
    sorted = rules.map { |r| [ r["from"].to_i, r["to"].to_i ] }.sort_by(&:first)
    sorted.each_cons(2) do |(_, prev_to), (next_from, _)|
      errors.add(:placement_points, "ranges must not overlap") if next_from <= prev_to
    end
  end
end
