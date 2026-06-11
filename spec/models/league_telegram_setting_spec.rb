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
