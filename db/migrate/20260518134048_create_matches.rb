class CreateMatches < ActiveRecord::Migration[8.0]
  def change
    create_table :matches do |t|
      t.references :tournament, null: false, foreign_key: true
      t.references :pair1, foreign_key: { to_table: :pairs }
      t.references :pair2, foreign_key: { to_table: :pairs }
      t.references :winner, foreign_key: { to_table: :pairs }
      t.integer :pair1_score
      t.integer :pair2_score
      t.integer :round_number, null: false
      t.integer :position, null: false
      t.string :status, default: "pending", null: false

      t.timestamps
    end

    add_index :matches, [ :tournament_id, :round_number, :position ], unique: true
  end
end
