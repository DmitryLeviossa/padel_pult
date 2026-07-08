# == Schema Information
#
# Table name: seasons
#
#  id          :bigint           not null, primary key
#  date_from   :date             not null
#  date_to     :date             not null
#  description :text
#  name        :string           default(""), not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  league_id   :bigint           not null
#
# Indexes
#
#  index_seasons_on_league_id  (league_id)
#
# Foreign Keys
#
#  fk_rails_...  (league_id => leagues.id)
#
FactoryBot.define do
  factory :season do
    association :league
    sequence(:name) { |n| "Season #{n}" }
    date_from { Date.today - 30 }
    date_to { Date.today + 30 }
  end
end
