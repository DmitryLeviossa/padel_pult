require "rails_helper"

RSpec.describe Tournaments::Matches::AdvanceWinnerService do
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
  let(:r1_matches) { bracket.matches.where(round_number: 1).order(:position) }
  let(:final) { bracket.matches.find_by(round_number: 2, position: 1) }

  context "when match has no winner" do
    it "does nothing" do
      match = r1_matches.first
      expect { described_class.new(match).call }.not_to change { final.reload.pair1_id }
    end
  end

  context "when match is in group stage" do
    it "does nothing" do
      tournament_mixed = create(:tournament, :registration, type: :mixed, league: league,
                                max_participants: 8, groups_count: 2, pairs_to_bracket: 1)
      tournament_mixed.brackets.destroy_all
      4.times { make_pair(tournament_mixed) }
      Tournaments::Matches::MixedGenerator.new(tournament_mixed).call

      group_match = tournament_mixed.matches.group_stage.first
      group_match.update!(winner_id: group_match.pair1_id, status: :completed)

      expect { described_class.new(group_match).call }
        .not_to change { tournament_mixed.matches.bracket.where.not(pair1_id: nil).count }
    end
  end

  context "when match is a bracket match with a winner" do
    it "assigns winner to pair1 of parent for odd-position match" do
      match = r1_matches.first
      winner_id = match.pair1_id
      match.update!(winner_id: winner_id, status: :completed)
      described_class.new(match).call
      expect(final.reload.pair1_id).to eq(winner_id)
    end

    it "assigns winner to pair2 of parent for even-position match" do
      match = r1_matches.second
      winner_id = match.pair1_id
      match.update!(winner_id: winner_id, status: :completed)
      described_class.new(match).call
      expect(final.reload.pair2_id).to eq(winner_id)
    end

    it "calculates parent position as ceil(position / 2)" do
      tournament_8 = create(:tournament, :registration, type: :olympic, loser_bracket: false,
                            max_participants: 16, league: league)
      tournament_8.brackets.destroy_all
      8.times { make_pair(tournament_8) }
      Tournaments::Matches::OlympicGenerator.new(tournament_8).call

      bracket_8 = tournament_8.brackets.first
      match = bracket_8.matches.find_by(round_number: 1, position: 3)
      parent = bracket_8.matches.find_by(round_number: 2, position: 2)
      match.update!(winner_id: match.pair1_id, status: :completed)
      described_class.new(match).call
      expect(parent.reload.pair1_id).to eq(match.pair1_id)
    end
  end

  context "when match is the final (no parent)" do
    it "does nothing" do
      match = r1_matches.first
      match.update!(winner_id: match.pair1_id, status: :completed)
      described_class.new(match).call

      final.update!(winner_id: final.reload.pair1_id, status: :completed)
      expect { described_class.new(final).call }.not_to raise_error
    end
  end
end
