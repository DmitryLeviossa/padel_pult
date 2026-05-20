# == Schema Information
#
# Table name: tournaments
#
#  id               :bigint           not null, primary key
#  description      :text
#  end_date         :datetime         not null
#  groups_count     :integer
#  location         :string
#  loser_bracket    :boolean          default(FALSE), not null
#  max_participants :integer          default(16), not null
#  name             :string           not null
#  pairs_to_bracket :integer
#  placement_points :jsonb            not null
#  sets_per_match   :integer          default(1), not null
#  start_date       :datetime         not null
#  status           :string           default("draft"), not null
#  type             :string           default("olympic"), not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  league_id        :bigint           not null
#
# Indexes
#
#  index_tournaments_on_league_id  (league_id)
#
# Foreign Keys
#
#  fk_rails_...  (league_id => leagues.id)
#
require "rails_helper"

RSpec.describe Tournament, type: :model do
  describe "sets_per_match" do
    let(:league) { create(:league, tournaments_quota: 5) }

    it "defaults to 1" do
      tournament = create(:tournament, league: league)
      expect(tournament.sets_per_match).to eq(1)
    end

    it "is configurable for olympic type" do
      tournament = build(:tournament, league: league, type: "olympic", sets_per_match: 3)
      expect(tournament).to be_valid
      expect(tournament.sets_per_match).to eq(3)
    end

    it "is invalid when less than 1" do
      tournament = build(:tournament, league: league, type: "olympic", sets_per_match: 0)
      expect(tournament).not_to be_valid
      expect(tournament.errors[:sets_per_match]).to be_present
    end

    it "resets to 1 for non-olympic types" do
      tournament = create(:tournament, league: league, type: "round_robin", sets_per_match: 3)
      expect(tournament.sets_per_match).to eq(1)
    end
  end

  describe "tournaments_quota enforcement" do
    context "when league has quota remaining" do
      let(:league) { create(:league, tournaments_quota: 3) }

      it "allows tournament creation" do
        tournament = build(:tournament, league: league)
        expect(tournament).to be_valid
      end

      it "decrements tournaments_quota by 1 after creation" do
        create(:tournament, league: league)
        expect(league.reload.tournaments_quota).to eq(2)
      end
    end

    context "when league quota is exactly 1" do
      let(:league) { create(:league, tournaments_quota: 1) }

      it "allows creation and decrements quota to 0" do
        create(:tournament, league: league)
        expect(league.reload.tournaments_quota).to eq(0)
      end
    end

    context "when league quota is 0" do
      let(:league) { create(:league, tournaments_quota: 0) }

      it "is invalid" do
        tournament = build(:tournament, league: league)
        expect(tournament).not_to be_valid
        expect(tournament.errors[:base]).to include(I18n.t("activerecord.errors.models.tournament.attributes.base.quota_exceeded"))
      end

      it "does not create a tournament" do
        expect { create(:tournament, league: league) }.to raise_error(ActiveRecord::RecordInvalid)
        expect(league.reload.tournaments_quota).to eq(0)
      end
    end
  end
end
