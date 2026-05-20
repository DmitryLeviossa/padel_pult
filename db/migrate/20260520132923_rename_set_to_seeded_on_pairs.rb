class RenameSetToSeededOnPairs < ActiveRecord::Migration[8.0]
  def change
    rename_column :pairs, :set, :seeded
  end
end
