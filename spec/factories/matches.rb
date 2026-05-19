# == Schema Information
#
# Table name: matches
#
#  id            :bigint           not null, primary key
#  group_number  :integer          default(0), not null
#  pair1_score   :integer
#  pair2_score   :integer
#  position      :integer          not null
#  round_number  :integer          not null
#  stage         :string           default("bracket"), not null
#  status        :string           default("pending"), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  pair1_id      :bigint
#  pair2_id      :bigint
#  tournament_id :bigint           not null
#  winner_id     :bigint
#
# Indexes
#
#  index_matches_on_pair1_id       (pair1_id)
#  index_matches_on_pair2_id       (pair2_id)
#  index_matches_on_tournament_id  (tournament_id)
#  index_matches_on_winner_id      (winner_id)
#  index_matches_uniqueness        (tournament_id,stage,group_number,round_number,position) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (pair1_id => pairs.id)
#  fk_rails_...  (pair2_id => pairs.id)
#  fk_rails_...  (tournament_id => tournaments.id)
#  fk_rails_...  (winner_id => pairs.id)
#
FactoryBot.define do
  factory :match do
    association :tournament
    association :pair1, factory: :pair
    association :pair2, factory: :pair
    round_number { 1 }
    sequence(:position) { |n| n }
    status { :pending }

    trait :completed do
      status { :completed }
      pair1_score { 6 }
      pair2_score { 4 }
    end

    trait :bye do
      status { :bye }
      pair2 { nil }
    end
  end
end
