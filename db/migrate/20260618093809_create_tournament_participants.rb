class CreateTournamentParticipants < ActiveRecord::Migration[8.0]
  def change
    create_table :tournament_participants do |t|
      t.references :tournament, null: false, foreign_key: true
      t.references :league_user, null: false, foreign_key: true
      t.integer :total_score, null: false, default: 0
      t.integer :placement

      t.timestamps
    end

    add_index :tournament_participants, [ :tournament_id, :league_user_id ], unique: true, name: "index_tournament_participants_uniqueness"
  end
end
