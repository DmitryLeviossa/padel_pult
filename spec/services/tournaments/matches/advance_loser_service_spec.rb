require "rails_helper"

RSpec.describe Tournaments::Matches::AdvanceLoserService do
  let(:league) { create(:league) }
  let(:tournament) { create(:tournament, :registration, type: :olympic, loser_bracket: false, league: league) }

  before { tournament.brackets.destroy_all }

  def make_pair(tournament)
    lu1 = create(:league_user, league: league)
    lu2 = create(:league_user, league: league)
    create(:pair, tournament: tournament, player1: lu1, player2: lu2)
  end

  before do
    4.times { make_pair(tournament) }
    Tournaments::Matches::OlympicGenerator.new(tournament).call
  end

  let(:bracket) { tournament.brackets.first }
  let(:total_rounds) { bracket.matches.maximum(:round_number) }
  let(:third_place) { bracket.matches.find_by(round_number: total_rounds, position: 2) }

  context "when match has no winner" do
    it "does nothing" do
      match = bracket.matches.find_by(round_number: 1, position: 1)
      match.update!(winner_id: nil)
      expect { described_class.new(match).call }.not_to change { third_place.reload.pair1_id }
    end
  end

  context "when match is not in penultimate round" do
    it "does nothing for a final match" do
      final = bracket.matches.find_by(round_number: total_rounds, position: 1)
      pair1 = tournament.pairs.first
      pair2 = tournament.pairs.second
      final.update!(pair1_id: pair1.id, pair2_id: pair2.id, winner_id: pair1.id, status: :completed)
      expect { described_class.new(final).call }.not_to change { third_place.reload.pair1_id }
    end
  end

  context "when match is in penultimate round" do
    let(:r1_matches) { bracket.matches.where(round_number: 1).order(:position) }

    it "assigns loser to pair1 of third-place match for odd-position match" do
      match = r1_matches.first
      loser_id = match.pair2_id
      match.update!(winner_id: match.pair1_id, status: :completed)
      described_class.new(match).call
      expect(third_place.reload.pair1_id).to eq(loser_id)
    end

    it "assigns loser to pair2 of third-place match for even-position match" do
      match = r1_matches.second
      loser_id = match.pair2_id
      match.update!(winner_id: match.pair1_id, status: :completed)
      described_class.new(match).call
      expect(third_place.reload.pair2_id).to eq(loser_id)
    end

    it "assigns loser correctly when pair2 wins" do
      match = r1_matches.first
      loser_id = match.pair1_id
      match.update!(winner_id: match.pair2_id, status: :completed)
      described_class.new(match).call
      expect(third_place.reload.pair1_id).to eq(loser_id)
    end
  end
end
