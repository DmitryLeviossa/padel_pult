# == Schema Information
#
# Table name: tournaments
#
#  id               :bigint           not null, primary key
#  description      :text
#  end_date         :datetime         not null
#  groups_count     :integer
#  loser_bracket    :boolean          default(FALSE), not null
#  max_participants :integer          default(16), not null
#  name             :string           not null
#  pairs_to_bracket :integer
#  placement_points :jsonb            not null
#  ranking_method   :string           default("score_delta"), not null
#  rounds_count     :integer
#  start_date       :datetime         not null
#  status           :string           default("draft"), not null
#  type             :string           default("olympic"), not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  club_id          :bigint
#  league_id        :bigint           not null
#
# Indexes
#
#  index_tournaments_on_club_id    (club_id)
#  index_tournaments_on_league_id  (league_id)
#
# Foreign Keys
#
#  fk_rails_...  (club_id => clubs.id)
#  fk_rails_...  (league_id => leagues.id)
#
FactoryBot.define do
  factory :tournament do
    sequence(:name) { |n| "Tournament #{n}" }
    start_date { Date.today + 1.month }
    end_date { Date.today + 1.month + 6.days }
    max_participants { 16 }
    status { :draft }
    type { :olympic }
    placement_points { [] }
    association :league
    association :club

    trait :registration do
      status { :registration }
    end

    trait :active do
      status { :active }
    end
  end
end
