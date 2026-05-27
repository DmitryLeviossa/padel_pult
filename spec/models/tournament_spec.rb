# == Schema Information
#
# Table name: tournaments
#
#  id               :bigint           not null, primary key
#  description      :text
#  end_date         :datetime         not null
#  groups_count     :integer
#  loser_bracket    :boolean          default(FALSE), not null
#  max_participants :integer          default(16), not null
#  name             :string           not null
#  pairs_to_bracket :integer
#  placement_points :jsonb            not null
#  start_date       :datetime         not null
#  status           :string           default("draft"), not null
#  type             :string           default("olympic"), not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  club_id          :bigint
#  league_id        :bigint           not null
#
# Indexes
#
#  index_tournaments_on_club_id    (club_id)
#  index_tournaments_on_league_id  (league_id)
#
# Foreign Keys
#
#  fk_rails_...  (club_id => clubs.id)
#  fk_rails_...  (league_id => leagues.id)
#
require "rails_helper"

RSpec.describe Tournament, type: :model do
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
        expect(tournament.errors[:base]).to include("квота на создание турниров в этой лиге исчерпана")
      end

      it "does not create a tournament" do
        expect { create(:tournament, league: league) }.to raise_error(ActiveRecord::RecordInvalid)
        expect(league.reload.tournaments_quota).to eq(0)
      end
    end
  end
end
