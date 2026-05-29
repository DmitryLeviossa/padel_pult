class CreateLeagueTelegramSettings < ActiveRecord::Migration[8.0]
  def change
    create_table :league_telegram_settings do |t|
      t.references :league, null: false, foreign_key: true, index: false
      t.string :match_results_thread_id
      t.string :announces_thread_id
      t.boolean :notify_match_results, null: false, default: false
      t.boolean :notify_tournament_registration_open, null: false, default: false

      t.timestamps
    end
    add_index :league_telegram_settings, :league_id, unique: true
  end
end
