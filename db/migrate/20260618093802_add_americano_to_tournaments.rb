class AddAmericanoToTournaments < ActiveRecord::Migration[8.0]
  def change
    add_column :tournaments, :rounds_count, :integer
  end
end
