require "rails_helper"

RSpec.describe Tournaments::UpdatePlacementsService do
  let(:league) { create(:league) }
  let(:tournament) do
    create(:tournament, :completed, league: league,
           placement_points: [
             { "from" => 1, "to" => 1, "points" => 100 },
             { "from" => 2, "to" => 2, "points" => 50 }
           ])
  end

  def make_pair(tournament, placement: nil)
    lu1 = create(:league_user, league: league)
    lu2 = create(:league_user, league: league)
    create(:pair, tournament: tournament, player1: lu1, player2: lu2, placement: placement)
  end

  describe "#call" do
    let(:pair1) { make_pair(tournament, placement: 1) }
    let(:pair2) { make_pair(tournament, placement: 2) }

    before do
      pair1.player1.increment!(:score, 100)
      pair1.player2.increment!(:score, 100)
      pair2.player1.increment!(:score, 50)
      pair2.player2.increment!(:score, 50)
    end

    let(:placements) do
      { pair1.id.to_s => "2", pair2.id.to_s => "1" }
    end

    it "returns true on success" do
      expect(described_class.new(tournament, placements).call).to be true
    end

    it "updates pair placements" do
      described_class.new(tournament, placements).call
      expect(pair1.reload.placement).to eq(2)
      expect(pair2.reload.placement).to eq(1)
    end

    it "reverses old points and applies new points" do
      described_class.new(tournament, placements).call
      # pair1 was 1st (100pts), now 2nd (50pts) => score: 100 - 100 + 50 = 50
      expect(pair1.player1.reload.score).to eq(50)
      expect(pair1.player2.reload.score).to eq(50)
      # pair2 was 2nd (50pts), now 1st (100pts) => score: 50 - 50 + 100 = 100
      expect(pair2.player1.reload.score).to eq(100)
      expect(pair2.player2.reload.score).to eq(100)
    end

    it "skips pairs with placement < 1" do
      placements_with_zero = { pair1.id.to_s => "0", pair2.id.to_s => "1" }
      described_class.new(tournament, placements_with_zero).call
      expect(pair1.reload.placement).to eq(1)
    end

    context "when player1_count_score is false" do
      before { pair1.update!(player1_count_score: false) }

      it "does not adjust score for player1" do
        described_class.new(tournament, placements).call
        expect(pair1.player1.reload.score).to eq(100)
        expect(pair1.player2.reload.score).to eq(50)
      end
    end

    context "when pair had no previous placement" do
      let(:pair_no_placement) { make_pair(tournament, placement: nil) }

      it "only applies new points without reversing" do
        new_placements = { pair_no_placement.id.to_s => "1" }
        described_class.new(tournament, new_placements).call
        expect(pair_no_placement.player1.reload.score).to eq(100)
        expect(pair_no_placement.player2.reload.score).to eq(100)
      end
    end
  end
end
