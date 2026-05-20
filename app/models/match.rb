# == Schema Information
#
# Table name: matches
#
#  id            :bigint           not null, primary key
#  group_number  :integer          default(0), not null
#  pair1_score   :integer
#  pair2_score   :integer
#  position      :integer          not null
#  round_number  :integer          not null
#  stage         :string           default("bracket"), not null
#  status        :string           default("pending"), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  pair1_id      :bigint
#  pair2_id      :bigint
#  tournament_id :bigint           not null
#  winner_id     :bigint
#
# Indexes
#
#  index_matches_on_pair1_id       (pair1_id)
#  index_matches_on_pair2_id       (pair2_id)
#  index_matches_on_tournament_id  (tournament_id)
#  index_matches_on_winner_id      (winner_id)
#  index_matches_uniqueness        (tournament_id,stage,group_number,round_number,position) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (pair1_id => pairs.id)
#  fk_rails_...  (pair2_id => pairs.id)
#  fk_rails_...  (tournament_id => tournaments.id)
#  fk_rails_...  (winner_id => pairs.id)
#
class Match < ApplicationRecord
  belongs_to :tournament
  belongs_to :pair1, class_name: "Pair", optional: true
  belongs_to :pair2, class_name: "Pair", optional: true
  belongs_to :winner, class_name: "Pair", optional: true
  has_many :match_sets, dependent: :destroy

  accepts_nested_attributes_for :match_sets

  enum :status, { pending: "pending", completed: "completed", bye: "bye" }
  enum :stage, { group_stage: "group", bracket: "bracket", loser_bracket: "loser_bracket" }

  scope :ordered, -> { order(:stage, :group_number, :round_number, :position) }

  def pair_display_name(pair)
    return "Свободен" if pair.nil?
    "#{pair.player1.full_name} / #{pair.player2.full_name}"
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
