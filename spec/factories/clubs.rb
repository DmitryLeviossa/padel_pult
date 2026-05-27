# == Schema Information
#
# Table name: clubs
#
#  id         :bigint           not null, primary key
#  address    :string
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
FactoryBot.define do
  factory :club do
    sequence(:name) { |n| "Club #{n}" }
    address { nil }
  end
end
