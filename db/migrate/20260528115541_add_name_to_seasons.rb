class AddNameToSeasons < ActiveRecord::Migration[8.0]
  def change
    add_column :seasons, :name, :string, null: false, default: ""
  end
end
