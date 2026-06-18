# == Schema Information
#
# Table name: tournament_participants
#
#  id             :bigint           not null, primary key
#  placement      :integer
#  total_score    :integer          default(0), not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  league_user_id :bigint           not null
#  tournament_id  :bigint           not null
#
# Indexes
#
#  index_tournament_participants_on_league_user_id  (league_user_id)
#  index_tournament_participants_on_tournament_id   (tournament_id)
#  index_tournament_participants_uniqueness         (tournament_id,league_user_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (league_user_id => league_users.id)
#  fk_rails_...  (tournament_id => tournaments.id)
#
class TournamentParticipant < ApplicationRecord
  belongs_to :tournament
  belongs_to :league_user

  validates :league_user_id, uniqueness: { scope: :tournament_id, message: "уже зарегистрирован на этот турнир" }

  delegate :user, :full_name, :score, to: :league_user
end
