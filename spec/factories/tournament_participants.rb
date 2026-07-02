FactoryBot.define do
  factory :tournament_participant do
    association :tournament
    association :league_user
  end
end
