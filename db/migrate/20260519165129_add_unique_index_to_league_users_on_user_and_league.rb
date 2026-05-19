class AddUniqueIndexToLeagueUsersOnUserAndLeague < ActiveRecord::Migration[8.0]
  def up
    # Remove duplicate rows keeping the one with the lowest id
    execute <<~SQL
      DELETE FROM league_users
      WHERE id NOT IN (
        SELECT MIN(id)
        FROM league_users
        GROUP BY user_id, league_id
      )
    SQL

    add_index :league_users, [:user_id, :league_id], unique: true
  end

  def down
    remove_index :league_users, [:user_id, :league_id]
  end
end
