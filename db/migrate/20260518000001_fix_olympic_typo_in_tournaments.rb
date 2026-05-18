class FixOlympicTypoInTournaments < ActiveRecord::Migration[8.0]
  def up
    Tournament.where(type: "olimpic").update_all(type: "olympic")
    change_column_default :tournaments, :type, from: "olimpic", to: "olympic"
  end

  def down
    Tournament.where(type: "olympic").update_all(type: "olimpic")
    change_column_default :tournaments, :type, from: "olympic", to: "olimpic"
  end
end
