class CreateLeagueUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :league_users do |t|
      t.references :league, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :score, null: false, default: 0
      t.timestamps
    end
  end
end
