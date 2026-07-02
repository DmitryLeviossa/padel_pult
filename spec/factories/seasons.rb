FactoryBot.define do
  factory :season do
    association :league
    sequence(:name) { |n| "Season #{n}" }
    date_from { Date.today - 30 }
    date_to { Date.today + 30 }
  end
end
