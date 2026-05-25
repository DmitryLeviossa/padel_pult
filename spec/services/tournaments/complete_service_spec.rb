require "rails_helper"

RSpec.describe Tournaments::CompleteService do
  let(:league) { create(:league) }
  let(:tournament) do
    create(:tournament, :active, league: league,
           placement_points: [
             { "from" => 1, "to" => 1, "points" => 100 },
             { "from" => 2, "to" => 2, "points" => 50 }
           ])
  end

  def make_pair(tournament)
    lu1 = create(:league_user, league: league)
    lu2 = create(:league_user, league: league)
    create(:pair, tournament: tournament, player1: lu1, player2: lu2)
  end

  describe "#call" do
    let(:pair1) { make_pair(tournament) }
    let(:pair2) { make_pair(tournament) }

    let(:placements) do
      { pair1.id.to_s => "1", pair2.id.to_s => "2" }
    end

    it "returns true on success" do
      expect(described_class.new(tournament, placements).call).to be true
    end

    it "marks the tournament as completed" do
      described_class.new(tournament, placements).call
      expect(tournament.reload.status).to eq("completed")
    end

    it "updates pair placements" do
      described_class.new(tournament, placements).call
      expect(pair1.reload.placement).to eq(1)
      expect(pair2.reload.placement).to eq(2)
    end

    it "increments player scores according to placement_points rules" do
      described_class.new(tournament, placements).call
      expect(pair1.player1.reload.score).to eq(100)
      expect(pair1.player2.reload.score).to eq(100)
      expect(pair2.player1.reload.score).to eq(50)
      expect(pair2.player2.reload.score).to eq(50)
    end

    it "skips pairs with placement < 1" do
      placements_with_zero = { pair1.id.to_s => "1", pair2.id.to_s => "0" }
      described_class.new(tournament, placements_with_zero).call
      expect(pair2.reload.placement).to be_nil
    end

    it "awards 0 points for placements not covered by rules" do
      placements_out_of_range = { pair1.id.to_s => "99" }
      described_class.new(tournament, placements_out_of_range).call
      expect(pair1.player1.reload.score).to eq(0)
    end
  end
end
