class AddSetsPerMatchToTournaments < ActiveRecord::Migration[8.0]
  def change
    add_column :tournaments, :sets_per_match, :integer, default: 1, null: false
  end
end
