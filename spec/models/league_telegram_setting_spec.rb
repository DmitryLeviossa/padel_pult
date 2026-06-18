# == Schema Information
#
# Table name: league_telegram_settings
#
#  id                      :bigint           not null, primary key
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  announces_thread_id     :string
#  chat_id                 :string
#  league_id               :bigint           not null
#  match_results_thread_id :string
#
# Indexes
#
#  index_league_telegram_settings_on_league_id  (league_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (league_id => leagues.id)
#
require "rails_helper"

RSpec.describe LeagueTelegramSetting, type: :model do
  describe "associations" do
    it "belongs to a league" do
      setting = create(:league_telegram_setting)
      expect(setting.league).to be_a(League)
    end
  end

  describe "uniqueness" do
    it "allows only one setting per league" do
      league = create(:league)
      create(:league_telegram_setting, league: league)
      duplicate = build(:league_telegram_setting, league: league)
      expect { duplicate.save! }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end
end
