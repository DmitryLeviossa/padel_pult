class CreateTournaments < ActiveRecord::Migration[8.0]
  def change
    create_table :tournaments do |t|
      t.string :name, null: false
      t.date :start_date, null: false
      t.date :end_date, null: false
      t.integer :max_participants, null: false, default: 16
      t.string :location
      t.string :type, null: false, default: :olympic
      t.string :status, null: false, default: :draft
      t.text :description
      t.references :league, null: false, foreign_key: true
      t.timestamps
    end
  end
end
