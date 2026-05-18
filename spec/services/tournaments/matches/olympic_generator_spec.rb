require "rails_helper"

RSpec.describe Tournaments::Matches::OlympicGenerator do
  let(:league) { create(:league) }
  let(:tournament) { create(:tournament, :registration, type: :olympic, league: league) }

  def make_pair(score: 0)
    lu1 = create(:league_user, league: league, score: score)
    lu2 = create(:league_user, league: league, score: score)
    create(:pair, tournament: tournament, player1: lu1, player2: lu2)
  end

  describe "#call" do
    context "with 4 pairs (exact power of 2)" do
      before { 4.times { make_pair } }

      it "creates 3 total matches (4/2 + 4/4)" do
        described_class.new(tournament).call
        expect(tournament.matches.count).to eq(3)
      end

      it "creates 2 rounds" do
        described_class.new(tournament).call
        expect(tournament.matches.pluck(:round_number).uniq.sort).to eq([ 1, 2 ])
      end

      it "has no bye matches" do
        described_class.new(tournament).call
        expect(tournament.matches.bye.count).to eq(0)
      end

      it "seeds higher-score pairs into earlier positions" do
        high_score_pair = make_pair(score: 100)
        # reload pairs so scores are current
        described_class.new(tournament.reload).call
        r1_matches = tournament.matches.where(round_number: 1).ordered
        top_match = r1_matches.first
        expect([ top_match.pair1_id, top_match.pair2_id ]).to include(high_score_pair.id)
      end
    end

    context "with 6 pairs (padded to 8)" do
      before { 6.times { make_pair } }

      it "creates 7 total matches" do
        described_class.new(tournament).call
        expect(tournament.matches.count).to eq(7)
      end

      it "creates 2 bye matches for top seeds" do
        described_class.new(tournament).call
        expect(tournament.matches.bye.count).to eq(2)
      end

      it "advances bye winners to round 2" do
        described_class.new(tournament).call
        bye_matches = tournament.matches.bye
        bye_matches.each do |bye|
          parent_pos = ((bye.position.to_f) / 2).ceil
          parent = tournament.matches.find_by(round_number: 2, position: parent_pos)
          winner_slot = bye.position.odd? ? parent.pair1_id : parent.pair2_id
          expect(winner_slot).to eq(bye.winner_id)
        end
      end
    end

    context "with 2 pairs" do
      before { 2.times { make_pair } }

      it "creates 1 final match" do
        described_class.new(tournament).call
        expect(tournament.matches.count).to eq(1)
      end
    end
  end
end
