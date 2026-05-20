# == Schema Information
#
# Table name: match_sets
#
#  id          :bigint           not null, primary key
#  pair1_score :integer          not null
#  pair2_score :integer          not null
#  set_number  :integer          not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  match_id    :bigint           not null
#
# Indexes
#
#  index_match_sets_on_match_id                 (match_id)
#  index_match_sets_on_match_id_and_set_number  (match_id,set_number) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (match_id => matches.id)
#
FactoryBot.define do
  factory :match_set do
    association :match
    sequence(:set_number) { |n| n }
    pair1_score { 6 }
    pair2_score { 4 }
  end
end
