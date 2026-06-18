# == Schema Information
#
# Table name: league_telegram_settings
#
#  id                      :bigint           not null, primary key
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  announces_thread_id     :string
#  chat_id                 :string
#  league_id               :bigint           not null
#  match_results_thread_id :string
#
# Indexes
#
#  index_league_telegram_settings_on_league_id  (league_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (league_id => leagues.id)
#
FactoryBot.define do
  factory :league_telegram_setting do
    association :league
    chat_id { "-100123456789" }
    match_results_thread_id { nil }
    announces_thread_id { nil }
  end
end
