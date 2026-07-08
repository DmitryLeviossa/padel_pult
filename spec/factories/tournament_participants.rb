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
FactoryBot.define do
  factory :tournament_participant do
    association :tournament
    association :league_user
  end
end
