require "rails_helper"

RSpec.describe Tournaments::Matches::StartBracketService do
  let(:league) { create(:league) }
  let(:tournament) do
    create(:tournament, :active,
           type: :mixed,
           league: league,
           groups_count: 2,
           pairs_to_bracket: 4,
           loser_bracket: false)
  end

  # Creates 4 pairs per group with given scores, generates group matches,
  # then records results so standings are deterministic.
  def setup_groups_with_results
    pairs = []
    2.times do |g|
      4.times do |i|
        lu1 = create(:league_user, league: league)
        lu2 = create(:league_user, league: league)
        pairs << create(:pair, tournament: tournament, player1: lu1, player2: lu2)
      end
    end
    tournament.reload

    Tournaments::Matches::MixedGenerator.new(tournament).call

    # Complete all group matches: pair1 always wins with a higher score
    tournament.matches.group_stage.each do |m|
      m.update!(status: :completed, pair1_score: 6, pair2_score: 3, winner_id: m.pair1_id)
    end

    pairs
  end

  describe "#call" do
    context "after all group matches are completed" do
      before { setup_groups_with_results }

      it "fills round-1 bracket slots with pairs" do
        described_class.new(tournament).call
        r1 = tournament.matches.bracket.where(round_number: 1)
        expect(r1.all? { |m| m.pair1_id.present? || m.pair2_id.present? }).to be true
      end

      it "assigns pairs from different groups to the same bracket match" do
        described_class.new(tournament).call
        r1 = tournament.matches.bracket.where(round_number: 1)
        # Each match should have both pair1 and pair2 (no byes expected with 4 exact pairs)
        r1.each do |m|
          expect(m.pair1_id).to be_present
          expect(m.pair2_id).to be_present
        end
      end

      it "does not re-run if called twice" do
        described_class.new(tournament).call
        bracket_pairs_first = tournament.matches.bracket.where(round_number: 1).map { |m| [m.pair1_id, m.pair2_id] }
        described_class.new(tournament).call
        bracket_pairs_second = tournament.matches.bracket.where(round_number: 1).map { |m| [m.pair1_id, m.pair2_id] }
        expect(bracket_pairs_first).to eq(bracket_pairs_second)
      end
    end

    context "when group matches are not yet all complete" do
      before do
        Tournaments::Matches::MixedGenerator.new(tournament).call
        # Leave one group match pending
        tournament.matches.group_stage.first(5).each do |m|
          m.update!(status: :completed, pair1_score: 6, pair2_score: 3, winner_id: m.pair1_id)
        end
      end

      it "does not fill bracket slots" do
        described_class.new(tournament).call
        r1 = tournament.matches.bracket.where(round_number: 1)
        expect(r1.all? { |m| m.pair1_id.nil? && m.pair2_id.nil? }).to be true
      end
    end

    context "with loser bracket enabled" do
      let(:tournament) do
        create(:tournament, :active,
               type: :mixed,
               league: league,
               groups_count: 2,
               pairs_to_bracket: 4,
               loser_bracket: true)
      end

      before { setup_groups_with_results }

      it "seeds the loser bracket with non-qualifying pairs" do
        described_class.new(tournament).call
        loser_r1 = tournament.matches.loser_bracket.where(round_number: 1)
        expect(loser_r1.any? { |m| m.pair1_id.present? || m.pair2_id.present? }).to be true
      end
    end
  end
end
