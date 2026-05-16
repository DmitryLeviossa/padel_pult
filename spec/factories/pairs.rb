FactoryBot.define do
  factory :pair do
    association :tournament
    association :player1, factory: :league_user
    association :player2, factory: :league_user
  end
end
