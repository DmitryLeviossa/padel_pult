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
    before { tournament.brackets.destroy_all }
    context "with 4 pairs (exact power of 2)" do
      before { 4.times { make_pair } }

      it "creates 4 total matches (2 round-1 + 1 final + 1 third-place)" do
        described_class.new(tournament).call
        expect(tournament.matches.count).to eq(4)
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
        described_class.new(tournament.reload).call
        r1_matches = tournament.matches.bracket.where(round_number: 1).ordered
        top_match = r1_matches.first
        expect([ top_match.pair1_id, top_match.pair2_id ]).to include(high_score_pair.id)
      end
    end

    context "with 6 pairs (padded to 8)" do
      before { 6.times { make_pair } }

      it "creates 8 total matches (4+2+1 bracket + 1 third-place)" do
        described_class.new(tournament).call
        expect(tournament.matches.count).to eq(8)
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
          parent = tournament.matches.bracket.find_by(round_number: 2, position: parent_pos)
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

    context "with loser_bracket enabled" do
      let(:tournament) { create(:tournament, :registration, type: :olympic, loser_bracket: true, league: league) }

      context "with 4 pairs" do
        before { 4.times { make_pair } }

        it "creates loser bracket matches in addition to main bracket" do
          described_class.new(tournament).call
          expect(tournament.matches.loser_bracket.count).to eq(1)
        end

        it "loser bracket match has no pairs assigned yet" do
          described_class.new(tournament).call
          lb = tournament.brackets.loser_bracket.first&.matches&.find_by(round_number: 1, position: 1)
          expect(lb.pair1_id).to be_nil
          expect(lb.pair2_id).to be_nil
        end
      end

      context "with 8 pairs" do
        before { 8.times { make_pair } }

        it "creates 2 loser bracket round-1 matches, 1 final, and 1 third-place" do
          described_class.new(tournament).call
          expect(tournament.matches.loser_bracket.where(round_number: 1).count).to eq(2)
          expect(tournament.matches.loser_bracket.where(round_number: 2).count).to eq(2)
        end
      end

      context "with 3 pairs (only 1 real round-1 match, too few losers)" do
        before { 3.times { make_pair } }

        it "does not create a loser bracket" do
          described_class.new(tournament).call
          expect(tournament.matches.loser_bracket.count).to eq(0)
        end
      end
    end
  end
end
