# == Schema Information
#
# Table name: tournaments
#
#  id               :bigint           not null, primary key
#  description      :text
#  end_date         :datetime         not null
#  location         :string
#  max_participants :integer          default(16), not null
#  name             :string           not null
#  placement_points :jsonb            not null
#  start_date       :datetime         not null
#  status           :string           default("draft"), not null
#  type             :string           default("olimpic"), not null
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
  has_many :pairs, dependent: :destroy

  enum :status, { draft: "draft", registration: "registration", active: "active", completed: "completed", cancelled: "cancelled" }
  enum :type, { olimpic: "olimpic", round_robin: "round_robin", mixed: "mixed" }

  validates :start_date, presence: true
  validates :end_date, presence: true
  validate :end_date_not_before_start_date
  validate :placement_points_valid

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

  def end_date_not_before_start_date
    return unless start_date && end_date
    errors.add(:end_date, :before_start_date) if end_date < start_date
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
