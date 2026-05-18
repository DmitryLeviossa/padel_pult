class AddPlacementToPairs < ActiveRecord::Migration[8.0]
  def change
    add_column :pairs, :placement, :integer
  end
end
