class AddNameAndPairsCountToBrackets < ActiveRecord::Migration[8.0]
  def change
    add_column :brackets, :name, :string
    add_column :brackets, :pairs_count, :integer
  end
end
