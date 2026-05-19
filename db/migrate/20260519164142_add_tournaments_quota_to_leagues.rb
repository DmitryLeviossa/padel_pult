class AddTournamentsQuotaToLeagues < ActiveRecord::Migration[8.0]
  def change
    add_column :leagues, :tournaments_quota, :integer, default: 5, null: false
  end
end
