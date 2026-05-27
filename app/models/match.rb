# == Schema Information
#
# Table name: matches
#
#  id            :bigint           not null, primary key
#  pair1_score   :integer
#  pair2_score   :integer
#  position      :integer          not null
#  round_number  :integer          not null
#  status        :string           default("pending"), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  bracket_id    :bigint           not null
#  pair1_id      :bigint
#  pair2_id      :bigint
#  tournament_id :bigint           not null
#  winner_id     :bigint
#
# Indexes
#
#  index_matches_on_bracket_id     (bracket_id)
#  index_matches_on_pair1_id       (pair1_id)
#  index_matches_on_pair2_id       (pair2_id)
#  index_matches_on_tournament_id  (tournament_id)
#  index_matches_on_winner_id      (winner_id)
#  index_matches_uniqueness        (bracket_id,round_number,position) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (bracket_id => brackets.id)
#  fk_rails_...  (pair1_id => pairs.id)
#  fk_rails_...  (pair2_id => pairs.id)
#  fk_rails_...  (tournament_id => tournaments.id)
#  fk_rails_...  (winner_id => pairs.id)
#
class Match < ApplicationRecord
  belongs_to :tournament
  belongs_to :bracket
  has_one_attached :result_card_image
  belongs_to :pair1, class_name: "Pair", optional: true
  belongs_to :pair2, class_name: "Pair", optional: true
  belongs_to :winner, class_name: "Pair", optional: true
  has_many :match_sets, dependent: :destroy

  accepts_nested_attributes_for :match_sets

  enum :status, { pending: "pending", completed: "completed", bye: "bye" }

  delegate :bracket_type, :group_stage?, :bracket?, :loser_bracket?, to: :bracket
  delegate :group_number, to: :bracket

  def stage = bracket_type

  scope :ordered, -> {
    includes(:bracket).references(:bracket)
                      .order("brackets.bracket_type, brackets.group_number, matches.round_number, matches.position")
  }
  scope :group_stage,    -> { joins(:bracket).where(brackets: { bracket_type: "group" }) }
  scope :bracket,        -> { joins(:bracket).where(brackets: { bracket_type: "bracket" }) }
  scope :loser_bracket,  -> { joins(:bracket).where(brackets: { bracket_type: "loser_bracket" }) }

  def has_downstream_results?
    return false if group_stage?
    return false if tournament.round_robin?

    parent = bracket.matches.find_by(
      round_number: round_number + 1,
      position: ((position.to_f) / 2).ceil
    )
    return true if parent&.winner_id.present?

    if bracket? && round_number == 1 && tournament.loser_bracket? && tournament.olympic?
      main_bracket = tournament.brackets.bracket.first
      real_positions = main_bracket&.matches
                                   &.where(round_number: 1)
                                   &.order(:position)
                                   &.pluck(:position) || []
      idx = real_positions.index(position)
      if idx
        lb = tournament.brackets.loser_bracket.first
        lb_match = lb&.matches&.find_by(round_number: 1, position: idx / 2 + 1)
        return true if lb_match&.winner_id.present?
      end
    end

    bracket_matches = bracket.matches
    total_rounds = bracket_matches.maximum(:round_number)
    if total_rounds && round_number == total_rounds - 1
      third_place = bracket_matches.find_by(round_number: total_rounds, position: 2)
      return true if third_place&.winner_id.present?
    end

    false
  end

  def pair_display_name(pair)
    return "Свободен" if pair.nil?
    "#{pair.player1.short_name} / #{pair.player2.short_name}"
  end

  def sets_won_by_pair1
    match_sets.count { |s| s.pair1_score > s.pair2_score }
  end

  def sets_won_by_pair2
    match_sets.count { |s| s.pair2_score > s.pair1_score }
  end

  def sets_score_summary
    match_sets.map { |s| "#{s.pair1_score}:#{s.pair2_score}" }.join(", ")
  end
end
