class CreateLeagues < ActiveRecord::Migration[8.0]
  def change
    create_table :leagues do |t|
      t.string :name, null: false
      t.text :description
      t.references :owner, null: false, foreign_key: { to_table: :users }
      t.timestamps
    end
  end
end
