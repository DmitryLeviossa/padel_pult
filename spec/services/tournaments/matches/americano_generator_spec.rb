require "rails_helper"

RSpec.describe Tournaments::Matches::AmericanoGenerator do
  let(:league) { create(:league) }
  let(:tournament) do
    create(:tournament, :registration,
           type: :americano,
           league: league,
           rounds_count: 1)
  end

  def add_participant
    lu = create(:league_user, league: league)
    create(:tournament_participant, tournament: tournament, league_user: lu)
  end

  describe "#call" do
    context "with fewer than 4 participants" do
      before { 3.times { add_participant } }

      it "does not create any matches" do
        expect {
          described_class.new(tournament).call
        }.not_to change(Match, :count)
      end
    end

    context "with 4 participants (1 court per rotation)" do
      before { 4.times { add_participant } }

      it "creates a bracket" do
        expect {
          described_class.new(tournament).call
        }.to change { tournament.brackets.count }.by(1)
      end

      it "creates matches for 1 cycle (n-1 rotations, 1 court each)" do
        described_class.new(tournament).call
        expect(tournament.matches.count).to eq(3)
      end

      it "assigns all matches to round 1" do
        described_class.new(tournament).call
        expect(tournament.matches.pluck(:round_number).uniq).to eq([ 1 ])
      end

      it "creates pairs for each match" do
        described_class.new(tournament).call
        expect(tournament.pairs.count).to eq(6)
      end
    end

    context "with 8 participants (2 courts per rotation)" do
      before { 8.times { add_participant } }

      it "creates 14 matches for 1 cycle (7 rotations × 2 courts)" do
        described_class.new(tournament).call
        expect(tournament.matches.count).to eq(14)
      end
    end

    context "with 2 rounds" do
      before do
        tournament.update!(rounds_count: 2)
        4.times { add_participant }
      end

      it "creates matches for 2 cycles" do
        described_class.new(tournament).call
        expect(tournament.matches.pluck(:round_number).uniq.sort).to eq([ 1, 2 ])
      end
    end
  end
end
