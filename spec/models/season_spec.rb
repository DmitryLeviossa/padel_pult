# == Schema Information
#
# Table name: seasons
#
#  id          :bigint           not null, primary key
#  date_from   :date             not null
#  date_to     :date             not null
#  description :text
#  name        :string           default(""), not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  league_id   :bigint           not null
#
# Indexes
#
#  index_seasons_on_league_id  (league_id)
#
# Foreign Keys
#
#  fk_rails_...  (league_id => leagues.id)
#
require "rails_helper"

RSpec.describe Season, type: :model do
  let(:league) { create(:league) }

  def build_season(attrs = {})
    defaults = { league: league, name: "S1", date_from: Date.today - 10, date_to: Date.today + 10 }
    build(:season, defaults.merge(attrs))
  end

  describe "validations" do
    it "is valid with all required fields" do
      expect(build_season).to be_valid
    end

    it "requires name" do
      expect(build_season(name: "")).not_to be_valid
    end

    it "requires date_from" do
      expect(build_season(date_from: nil)).not_to be_valid
    end

    it "requires date_to" do
      expect(build_season(date_to: nil)).not_to be_valid
    end

    it "is invalid when date_to is before date_from" do
      s = build_season(date_from: Date.today, date_to: Date.today - 1)
      expect(s).not_to be_valid
      expect(s.errors[:date_to]).to include("не может быть раньше даты начала")
    end

    it "is valid when date_to equals date_from" do
      expect(build_season(date_from: Date.today, date_to: Date.today)).to be_valid
    end
  end

  describe "#status" do
    it "returns :upcoming when date_from is in the future" do
      s = build_season(date_from: Date.today + 5, date_to: Date.today + 10)
      expect(s.status).to eq(:upcoming)
      expect(s).to be_upcoming
    end

    it "returns :active when today is within the range" do
      s = build_season(date_from: Date.today - 1, date_to: Date.today + 1)
      expect(s.status).to eq(:active)
      expect(s).to be_active
    end

    it "returns :finished when date_to is in the past" do
      s = build_season(date_from: Date.today - 10, date_to: Date.today - 1)
      expect(s.status).to eq(:finished)
      expect(s).to be_finished
    end
  end
end
