class AddScoresToPairs < ActiveRecord::Migration[8.0]
  def change
    add_column :pairs, :player1_score, :integer, null: false, default: 0
    add_column :pairs, :player2_score, :integer, null: false, default: 0

    reversible do |dir|
      dir.up do
        execute <<~SQL
          UPDATE pairs
          SET player1_score = (SELECT score FROM league_users WHERE league_users.id = pairs.player1_id),
              player2_score = (SELECT score FROM league_users WHERE league_users.id = pairs.player2_id)
        SQL
      end
    end
  end
end
