class MoveChatIdToLeagueTelegramSettings < ActiveRecord::Migration[8.0]
  def up
    add_column :league_telegram_settings, :chat_id, :string

    execute <<~SQL
      INSERT INTO league_telegram_settings (league_id, chat_id, created_at, updated_at)
      SELECT id, chat_id, NOW(), NOW()
      FROM leagues
      WHERE chat_id IS NOT NULL
      ON CONFLICT (league_id) DO UPDATE SET chat_id = EXCLUDED.chat_id
    SQL

    remove_column :leagues, :chat_id
  end

  def down
    add_column :leagues, :chat_id, :string

    execute <<~SQL
      UPDATE leagues
      SET chat_id = league_telegram_settings.chat_id
      FROM league_telegram_settings
      WHERE league_telegram_settings.league_id = leagues.id
        AND league_telegram_settings.chat_id IS NOT NULL
    SQL

    remove_column :league_telegram_settings, :chat_id
  end
end
