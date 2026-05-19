class AddMixedConfigToTournaments < ActiveRecord::Migration[8.0]
  def change
    add_column :tournaments, :groups_count, :integer
    add_column :tournaments, :pairs_to_bracket, :integer
    add_column :tournaments, :loser_bracket, :boolean, default: false, null: false
  end
end
