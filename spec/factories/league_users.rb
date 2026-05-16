FactoryBot.define do
  factory :league_user do
    association :league
    association :user
    score { 0 }
  end
end
