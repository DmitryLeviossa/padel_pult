class AddRankingMethodToTournaments < ActiveRecord::Migration[8.0]
  def change
    add_column :tournaments, :ranking_method, :string, default: "score_delta", null: false
  end
end
