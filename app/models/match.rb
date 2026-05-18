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
#  pair1_id      :bigint
#  pair2_id      :bigint
#  tournament_id :bigint           not null
#  winner_id     :bigint
#
# Indexes
#
#  index_matches_on_pair1_id                                     (pair1_id)
#  index_matches_on_pair2_id                                     (pair2_id)
#  index_matches_on_tournament_id                                (tournament_id)
#  index_matches_on_tournament_id_and_round_number_and_position  (tournament_id,round_number,position) UNIQUE
#  index_matches_on_winner_id                                    (winner_id)
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

  enum :status, { pending: "pending", completed: "completed", bye: "bye" }

  scope :ordered, -> { order(:round_number, :position) }

  def pair_display_name(pair)
    return I18n.t("matches.bye") if pair.nil?
    "#{pair.player1.full_name} / #{pair.player2.full_name}"
  end
end
