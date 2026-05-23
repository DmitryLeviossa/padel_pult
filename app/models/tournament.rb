# == Schema Information
#
# Table name: tournaments
#
#  id               :bigint           not null, primary key
#  description      :text
#  end_date         :datetime         not null
#  groups_count     :integer
#  location         :string
#  loser_bracket    :boolean          default(FALSE), not null
#  max_participants :integer          default(16), not null
#  name             :string           not null
#  pairs_to_bracket :integer
#  placement_points :jsonb            not null
#  start_date       :datetime         not null
#  status           :string           default("draft"), not null
#  type             :string           default("olympic"), not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  league_id        :bigint           not null
#
# Indexes
#
#  index_tournaments_on_league_id  (league_id)
#
# Foreign Keys
#
#  fk_rails_...  (league_id => leagues.id)
#
class Tournament < ApplicationRecord
  self.inheritance_column = nil

  belongs_to :league
  has_many :brackets, dependent: :destroy
  has_many :matches, dependent: :destroy
  has_many :pairs, dependent: :destroy

  enum :status, { draft: "draft", registration: "registration", active: "active", completed: "completed", cancelled: "cancelled" }
  enum :type, { olympic: "olympic", round_robin: "round_robin", mixed: "mixed" }

  validates :start_date, presence: true
  validates :end_date, presence: true
  validates :groups_count, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :pairs_to_bracket, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validate :end_date_not_before_start_date
  validate :placement_points_valid
  validate :mixed_config_present, if: :mixed?
  validate :pairs_to_bracket_valid_for_groups, if: :mixed?
  validate :league_quota_available, on: :create

  after_create :decrement_league_quota
  after_create :generate_match_structure
  after_update :regenerate_match_structure, if: :structure_params_changed?

  def all_matches_completed?
    matches.any? && !matches.pending.exists?
  end

  def max_pairs
    max_participants / 2
  end

  def eligible_pairs
    pairs.sort_by { |p| [ -p.score, p.created_at ] }.first(max_pairs)
  end

  def points_for_place(position)
    Array(placement_points).each do |rule|
      from = rule["from"].to_i
      to   = rule["to"].to_i
      return rule["points"].to_i if position >= from && position <= to
    end
    0
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[name location status type start_date end_date]
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
