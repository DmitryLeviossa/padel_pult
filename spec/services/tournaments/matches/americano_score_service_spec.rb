require "rails_helper"

RSpec.describe Tournaments::Matches::AmericanoScoreService do
  let(:league) { create(:league) }
  let(:tournament) { create(:tournament, :active, type: :americano, league: league, rounds_count: 1) }

  def make_participant(lu)
    create(:tournament_participant, tournament: tournament, league_user: lu)
  end

  let(:lu1) { create(:league_user, league: league) }
  let(:lu2) { create(:league_user, league: league) }
  let(:lu3) { create(:league_user, league: league) }
  let(:lu4) { create(:league_user, league: league) }

  let!(:tp1) { make_participant(lu1) }
  let!(:tp2) { make_participant(lu2) }
  let!(:tp3) { make_participant(lu3) }
  let!(:tp4) { make_participant(lu4) }

  let(:pair1) { create(:pair, tournament: tournament, player1: lu1, player2: lu2) }
  let(:pair2) { create(:pair, tournament: tournament, player1: lu3, player2: lu4) }

  def create_completed_match(p1_score, p2_score)
    bracket = tournament.brackets.find_or_create_by!(bracket_type: "bracket", group_number: 0)
    match = bracket.matches.create!(
      tournament: tournament,
      pair1: pair1,
      pair2: pair2,
      round_number: 1,
      position: 1,
      status: :completed,
      winner_id: p1_score >= p2_score ? pair1.id : pair2.id
    )
    match.match_sets.create!(set_number: 1, pair1_score: p1_score, pair2_score: p2_score)
    match
  end

  describe "#call" do
    it "does nothing for non-americano tournament" do
      other = create(:tournament, :active, type: :olympic, league: league)
      other_pair1 = create(:pair, tournament: other, player1: lu1, player2: lu2)
      other_pair2 = create(:pair, tournament: other, player1: lu3, player2: lu4)
      # Reuse a pre-generated match slot from the structure generator
      match = other.matches.find_by!(round_number: 1, position: 1)
      match.update_columns(pair1_id: other_pair1.id, pair2_id: other_pair2.id,
                           status: "completed", winner_id: other_pair1.id)
      match.match_sets.create!(set_number: 1, pair1_score: 10, pair2_score: 5)

      expect { described_class.new(match).call }.not_to change { tp1.reload.total_score }
    end

    it "does nothing if match is not completed" do
      bracket = tournament.brackets.find_or_create_by!(bracket_type: "bracket", group_number: 0)
      match = bracket.matches.create!(
        tournament: tournament, pair1: pair1, pair2: pair2,
        round_number: 1, position: 1, status: :pending
      )
      expect { described_class.new(match).call }.not_to change { tp1.reload.total_score }
    end

    it "adds pair1 set scores to pair1 players' total_score" do
      match = create_completed_match(17, 15)
      described_class.new(match).call

      expect(tp1.reload.total_score).to eq(17)
      expect(tp2.reload.total_score).to eq(17)
    end

    it "adds pair2 set scores to pair2 players' total_score" do
      match = create_completed_match(17, 15)
      described_class.new(match).call

      expect(tp3.reload.total_score).to eq(15)
      expect(tp4.reload.total_score).to eq(15)
    end

    it "accumulates scores across multiple calls" do
      m1 = create_completed_match(10, 8)
      described_class.new(m1).call

      bracket = tournament.brackets.first
      m2 = bracket.matches.create!(
        tournament: tournament, pair1: pair1, pair2: pair2,
        round_number: 2, position: 1, status: :completed, winner_id: pair1.id
      )
      m2.match_sets.create!(set_number: 1, pair1_score: 12, pair2_score: 6)
      described_class.new(m2).call

      expect(tp1.reload.total_score).to eq(22)
      expect(tp3.reload.total_score).to eq(14)
    end
  end
end
