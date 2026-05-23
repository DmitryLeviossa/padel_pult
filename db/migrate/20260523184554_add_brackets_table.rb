class AddBracketsTable < ActiveRecord::Migration[8.0]
  def up
    create_table :brackets do |t|
      t.references :tournament, null: false, foreign_key: true
      t.string :bracket_type, null: false
      t.integer :group_number, default: 0, null: false
      t.timestamps
    end

    add_index :brackets, [ :tournament_id, :bracket_type, :group_number ],
              unique: true, name: "index_brackets_uniqueness"

    add_reference :matches, :bracket, foreign_key: true

    # Backfill: one bracket per unique (tournament_id, stage, group_number) combo
    execute <<~SQL
      INSERT INTO brackets (tournament_id, bracket_type, group_number, created_at, updated_at)
      SELECT DISTINCT tournament_id, stage, group_number, NOW(), NOW()
      FROM matches
    SQL

    execute <<~SQL
      UPDATE matches
      SET bracket_id = brackets.id
      FROM brackets
      WHERE matches.tournament_id = brackets.tournament_id
        AND matches.stage         = brackets.bracket_type
        AND matches.group_number  = brackets.group_number
    SQL

    change_column_null :matches, :bracket_id, false

    remove_index :matches, name: "index_matches_uniqueness"
    add_index :matches, [ :bracket_id, :round_number, :position ],
              unique: true, name: "index_matches_uniqueness"

    remove_column :matches, :stage
    remove_column :matches, :group_number
  end

  def down
    add_column :matches, :stage, :string, default: "bracket", null: false
    add_column :matches, :group_number, :integer, default: 0, null: false

    execute <<~SQL
      UPDATE matches
      SET stage        = brackets.bracket_type,
          group_number = brackets.group_number
      FROM brackets
      WHERE matches.bracket_id = brackets.id
    SQL

    remove_index :matches, name: "index_matches_uniqueness"
    add_index :matches, [ :tournament_id, :stage, :group_number, :round_number, :position ],
              unique: true, name: "index_matches_uniqueness"

    remove_reference :matches, :bracket, foreign_key: true
    drop_table :brackets
  end
end
