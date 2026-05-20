FactoryBot.define do
  factory :match_set do
    association :match
    sequence(:set_number) { |n| n }
    pair1_score { 6 }
    pair2_score { 4 }
  end
end
