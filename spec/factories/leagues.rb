FactoryBot.define do
  factory :league do
    sequence(:name) { |n| "League #{n}" }
    association :owner, factory: :user
  end
end
