FactoryBot.define do
  factory :league_telegram_setting do
    association :league
    chat_id { "-100123456789" }
    match_results_thread_id { nil }
    announces_thread_id { nil }
  end
end
