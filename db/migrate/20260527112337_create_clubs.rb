class CreateClubs < ActiveRecord::Migration[8.0]
  def up
    create_table :clubs do |t|
      t.string :name, null: false
      t.string :address

      t.timestamps
    end

    add_reference :tournaments, :club, foreign_key: true

    padel61 = Club.create!(name: "Padel61", address: "г. Ростов-на-Дону, ул. Чемордачка, 105")
    Tournament.update_all(club_id: padel61.id)

    remove_column :tournaments, :location
  end

  def down
    add_column :tournaments, :location, :string
    remove_reference :tournaments, :club, foreign_key: true
    drop_table :clubs
  end
end
