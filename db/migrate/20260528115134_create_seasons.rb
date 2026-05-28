class CreateSeasons < ActiveRecord::Migration[8.0]
  def change
    create_table :seasons do |t|
      t.references :league, null: false, foreign_key: true
      t.date :date_from, null: false
      t.date :date_to, null: false
      t.text :description

      t.timestamps
    end
  end
end
