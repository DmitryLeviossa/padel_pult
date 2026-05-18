class ChangeStartDateEndDateToDatetimeInTournaments < ActiveRecord::Migration[8.0]
  def change
    change_column :tournaments, :start_date, :datetime, null: false
    change_column :tournaments, :end_date, :datetime, null: false
  end
end
