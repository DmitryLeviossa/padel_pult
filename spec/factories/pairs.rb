# == Schema Information
#
# Table name: pairs
#
#  id            :bigint           not null, primary key
#  placement     :integer
#  player1_score :integer          default(0), not null
#  player2_score :integer          default(0), not null
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
FactoryBot.define do
  factory :pair do
    association :tournament
    association :player1, factory: :league_user
    association :player2, factory: :league_user
  end
end
