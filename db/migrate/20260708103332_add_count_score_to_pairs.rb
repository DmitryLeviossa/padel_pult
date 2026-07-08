class AddCountScoreToPairs < ActiveRecord::Migration[8.0]
  def change
    add_column :pairs, :player1_count_score, :boolean, default: true, null: false
    add_column :pairs, :player2_count_score, :boolean, default: true, null: false
  end
end
