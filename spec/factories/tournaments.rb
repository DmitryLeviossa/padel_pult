FactoryBot.define do
  factory :tournament do
    sequence(:name) { |n| "Tournament #{n}" }
    start_date { Date.today + 1.month }
    end_date { Date.today + 1.month + 6.days }
    max_participants { 16 }
    status { :draft }
    type { :olimpic }
    placement_points { [] }
    association :league

    trait :active do
      status { :active }
    end
  end
end
