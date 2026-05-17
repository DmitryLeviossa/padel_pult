class CreateLeagueInvitations < ActiveRecord::Migration[8.0]
  def change
    create_table :league_invitations do |t|
      t.references :league, null: false, foreign_key: true
      t.references :invited_user, null: false, foreign_key: { to_table: :users }
      t.references :invited_by, null: false, foreign_key: { to_table: :users }
      t.integer :status, null: false, default: 0

      t.timestamps
    end

    add_index :league_invitations, [:league_id, :invited_user_id], unique: true
  end
end
