FactoryBot.define do
  factory :league_invitation do
    association :league
    association :invited_user, factory: :user
    association :invited_by, factory: :user
    status { :pending }
  end
end
