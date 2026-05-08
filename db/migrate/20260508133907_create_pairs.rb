class CreatePairs < ActiveRecord::Migration[8.0]
  def change
    create_table :pairs do |t|
      t.references :player1, null: false, foreign_key: { to_table: :league_users }
      t.references :player2, null: false, foreign_key: { to_table: :league_users }
      t.references :tournament, null: false, foreign_key: { to_table: :tournaments }

      t.timestamps
    end
  end
end
