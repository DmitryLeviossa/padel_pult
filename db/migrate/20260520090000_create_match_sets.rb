class CreateMatchSets < ActiveRecord::Migration[8.0]
  def change
    create_table :match_sets do |t|
      t.references :match, null: false, foreign_key: true
      t.integer :set_number, null: false
      t.integer :pair1_score, null: false
      t.integer :pair2_score, null: false

      t.timestamps
    end

    add_index :match_sets, [:match_id, :set_number], unique: true
  end
end
