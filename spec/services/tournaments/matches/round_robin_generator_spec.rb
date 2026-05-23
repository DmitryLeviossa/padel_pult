require "rails_helper"

RSpec.describe Tournaments::Matches::RoundRobinGenerator do
  let(:league) { create(:league) }
  let(:tournament) { create(:tournament, :registration, type: :round_robin, league: league) }

  def make_pair
    lu1 = create(:league_user, league: league)
    lu2 = create(:league_user, league: league)
    create(:pair, tournament: tournament, player1: lu1, player2: lu2)
  end

  describe "#call" do
    before { tournament.brackets.destroy_all }

    context "with 4 pairs (even)" do
      before { 4.times { make_pair } }

      it "creates n*(n-1)/2 matches" do
        described_class.new(tournament).call
        expect(tournament.matches.count).to eq(6)
      end

      it "creates n-1 rounds" do
        described_class.new(tournament).call
        expect(tournament.matches.pluck(:round_number).uniq.sort).to eq([ 1, 2, 3 ])
      end

      it "each pair plays every other pair exactly once" do
        described_class.new(tournament).call
        pairs = tournament.pairs.to_a
        pairs.combination(2).each do |p1, p2|
          count = tournament.matches.where(
            "(pair1_id = ? AND pair2_id = ?) OR (pair1_id = ? AND pair2_id = ?)",
            p1.id, p2.id, p2.id, p1.id
          ).count
          expect(count).to eq(1), "Expected #{p1.id} vs #{p2.id} exactly once"
        end
      end
    end

    context "with 3 pairs (odd)" do
      before { 3.times { make_pair } }

      it "creates n*(n-1)/2 matches" do
        described_class.new(tournament).call
        expect(tournament.matches.count).to eq(3)
      end

      it "each pair plays every other pair exactly once" do
        described_class.new(tournament).call
        pairs = tournament.pairs.to_a
        pairs.combination(2).each do |p1, p2|
          count = tournament.matches.where(
            "(pair1_id = ? AND pair2_id = ?) OR (pair1_id = ? AND pair2_id = ?)",
            p1.id, p2.id, p2.id, p1.id
          ).count
          expect(count).to eq(1)
        end
      end
    end
  end
end
