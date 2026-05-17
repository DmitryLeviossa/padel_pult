# == Schema Information
#
# Table name: pairs
#
#  id            :bigint           not null, primary key
#  placement     :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  player1_id    :bigint           not null
#  player2_id    :bigint           not null
#  tournament_id :bigint           not null
#
# Indexes
#
#  index_pairs_on_player1_id     (player1_id)
#  index_pairs_on_player2_id     (player2_id)
#  index_pairs_on_tournament_id  (tournament_id)
#
# Foreign Keys
#
#  fk_rails_...  (player1_id => league_users.id)
#  fk_rails_...  (player2_id => league_users.id)
#  fk_rails_...  (tournament_id => tournaments.id)
#
class Pair < ApplicationRecord
  belongs_to :player1, class_name: "LeagueUser"
  belongs_to :player2, class_name: "LeagueUser"
  belongs_to :tournament

  validate :players_must_be_different
  validate :each_player_once_per_tournament

  def score
    player1.score + player2.score
  end

  def partner_for(league_user_ids)
    league_user_ids.include?(player1_id) ? player2 : player1
  end

  private

  def players_must_be_different
    errors.add(:player2, :same_as_player1) if player1_id.present? && player1_id == player2_id
  end

  def each_player_once_per_tournament
    return unless tournament_id.present?

    occupied = Pair.where(tournament_id: tournament_id)
                   .where.not(id: id)
                   .where("player1_id IN (?) OR player2_id IN (?)", [ player1_id, player2_id ], [ player1_id, player2_id ])
    errors.add(:base, :player_already_registered) if occupied.exists?
  end
end
