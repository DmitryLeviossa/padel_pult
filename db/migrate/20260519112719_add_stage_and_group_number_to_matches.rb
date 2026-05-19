class AddStageAndGroupNumberToMatches < ActiveRecord::Migration[8.0]
  def change
    add_column :matches, :stage, :string, null: false, default: "bracket"
    add_column :matches, :group_number, :integer, null: false, default: 0

    remove_index :matches, [:tournament_id, :round_number, :position],
                 name: "index_matches_on_tournament_id_and_round_number_and_position"

    add_index :matches,
              [:tournament_id, :stage, :group_number, :round_number, :position],
              unique: true,
              name: "index_matches_uniqueness"
  end
end
