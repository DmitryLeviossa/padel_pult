class CreateLeagues < ActiveRecord::Migration[8.0]
  def change
    create_table :leagues do |t|
      t.string :name, null: false
      t.text :description
      t.references :user, null: false, foreign_key: true, index: true
      t.timestamps
    end
  end
end
