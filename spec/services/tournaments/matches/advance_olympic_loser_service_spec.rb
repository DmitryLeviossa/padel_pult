require "rails_helper"

RSpec.describe Tournaments::Matches::AdvanceOlympicLoserService do
  let(:league) { create(:league) }

  def make_pair(tournament)
    lu1 = create(:league_user, league: league)
    lu2 = create(:league_user, league: league)
    create(:pair, tournament: tournament, player1: lu1, player2: lu2)
  end

  context "when tournament has loser_bracket disabled" do
    let(:tournament) { create(:tournament, :registration, type: :olympic, loser_bracket: false, league: league) }

    it "does nothing" do
      4.times { make_pair(tournament) }
      Tournaments::Matches::OlympicGenerator.new(tournament).call

      match = tournament.matches.where(stage: :bracket, round_number: 1).first
      match.update!(winner_id: match.pair1_id, status: :completed)

      expect { described_class.new(match).call }
        .not_to change { tournament.matches.loser_bracket.count }
    end
  end

  context "when tournament has loser_bracket enabled" do
    let(:tournament) { create(:tournament, :registration, type: :olympic, loser_bracket: true, league: league) }

    context "with 4 pairs (2 real round-1 matches → 2 losers → 1 loser bracket match)" do
      before { 4.times { make_pair(tournament) } }

      it "creates 1 loser bracket match on generation" do
        Tournaments::Matches::OlympicGenerator.new(tournament).call
        expect(tournament.matches.loser_bracket.count).to eq(1)
      end

      it "places first loser into pair1 of the loser bracket match" do
        Tournaments::Matches::OlympicGenerator.new(tournament).call

        r1 = tournament.matches.where(stage: :bracket, round_number: 1).order(:position).first
        loser_id = r1.pair2_id
        r1.update!(winner_id: r1.pair1_id, status: :completed)
        described_class.new(r1).call

        lb_match = tournament.matches.find_by(stage: :loser_bracket, round_number: 1, position: 1)
        expect(lb_match.pair1_id).to eq(loser_id)
      end

      it "places second loser into pair2 of the loser bracket match" do
        Tournaments::Matches::OlympicGenerator.new(tournament).call

        r1_matches = tournament.matches.where(stage: :bracket, round_number: 1).order(:position)
        r1_matches.each do |m|
          m.update!(winner_id: m.pair1_id, status: :completed)
          described_class.new(m).call
        end

        lb_match = tournament.matches.find_by(stage: :loser_bracket, round_number: 1, position: 1)
        second_loser_id = r1_matches.second.pair2_id
        expect(lb_match.pair2_id).to eq(second_loser_id)
      end
    end

    context "with 8 pairs (4 real round-1 matches → 4 losers → 2 loser bracket round-1 matches)" do
      before { 8.times { make_pair(tournament) } }

      it "creates loser bracket with 2 round-1 matches, 1 final, and 1 third-place" do
        Tournaments::Matches::OlympicGenerator.new(tournament).call
        lb_matches = tournament.matches.loser_bracket
        expect(lb_matches.where(round_number: 1).count).to eq(2)
        # round 2: 1 final (position 1) + 1 third-place (position 2)
        expect(lb_matches.where(round_number: 2).count).to eq(2)
      end

      it "places losers into correct loser bracket slots by position" do
        Tournaments::Matches::OlympicGenerator.new(tournament).call

        r1_matches = tournament.matches.where(stage: :bracket, round_number: 1).order(:position)
        r1_matches.each do |m|
          m.update!(winner_id: m.pair1_id, status: :completed)
          described_class.new(m).call
        end

        lb1 = tournament.matches.find_by(stage: :loser_bracket, round_number: 1, position: 1)
        lb2 = tournament.matches.find_by(stage: :loser_bracket, round_number: 1, position: 2)

        expect(lb1.pair1_id).to eq(r1_matches[0].pair2_id)
        expect(lb1.pair2_id).to eq(r1_matches[1].pair2_id)
        expect(lb2.pair1_id).to eq(r1_matches[2].pair2_id)
        expect(lb2.pair2_id).to eq(r1_matches[3].pair2_id)
      end
    end

    context "with 6 pairs (2 byes → 2 real round-1 matches → 2 losers → 1 loser bracket match)" do
      before { 6.times { make_pair(tournament) } }

      it "creates 1 loser bracket match (byes produce no losers)" do
        Tournaments::Matches::OlympicGenerator.new(tournament).call
        expect(tournament.matches.loser_bracket.count).to eq(1)
      end

      it "ignores bye matches and only advances real losers" do
        Tournaments::Matches::OlympicGenerator.new(tournament).call

        real_r1 = tournament.matches
          .where(stage: :bracket, round_number: 1)
          .where.not(status: :bye)
          .order(:position)

        real_r1.each do |m|
          m.update!(winner_id: m.pair1_id, status: :completed)
          described_class.new(m).call
        end

        lb_match = tournament.matches.find_by(stage: :loser_bracket, round_number: 1, position: 1)
        expect(lb_match.pair1_id).to eq(real_r1.first.pair2_id)
        expect(lb_match.pair2_id).to eq(real_r1.second.pair2_id)
      end
    end

    it "does nothing for a non-round-1 match" do
      4.times { make_pair(tournament) }
      Tournaments::Matches::OlympicGenerator.new(tournament).call

      final = tournament.matches.where(stage: :bracket, round_number: 2, position: 1).first
      final.update!(pair1_id: tournament.pairs.first.id, pair2_id: tournament.pairs.second.id,
                    winner_id: tournament.pairs.first.id, status: :completed)

      expect { described_class.new(final).call }
        .not_to change { tournament.matches.where(stage: :loser_bracket).where.not(pair1_id: nil).count }
    end
  end
end
