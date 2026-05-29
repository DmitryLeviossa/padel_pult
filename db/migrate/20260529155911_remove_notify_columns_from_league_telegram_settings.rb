class RemoveNotifyColumnsFromLeagueTelegramSettings < ActiveRecord::Migration[8.0]
  def change
    remove_column :league_telegram_settings, :notify_match_results, :boolean
    remove_column :league_telegram_settings, :notify_tournament_registration_open, :boolean
  end
end
