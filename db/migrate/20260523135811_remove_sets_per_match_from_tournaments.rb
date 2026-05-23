class RemoveSetsPerMatchFromTournaments < ActiveRecord::Migration[8.0]
  def change
    remove_column :tournaments, :sets_per_match, :integer
  end
end
