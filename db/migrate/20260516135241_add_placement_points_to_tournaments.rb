class AddPlacementPointsToTournaments < ActiveRecord::Migration[8.0]
  def change
    add_column :tournaments, :placement_points, :jsonb, default: [], null: false
  end
end
