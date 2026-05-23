require "rails_helper"

RSpec.describe Tournaments::Matches::MixedGenerator do
  let(:league) { create(:league) }
  let(:tournament) do
    create(:tournament, :registration,
           type: :mixed,
           league: league,
           groups_count: 2,
           pairs_to_bracket: 4,
           loser_bracket: false)
  end

  def make_pair(score: 0)
    lu1 = create(:league_user, league: league, score: score)
    lu2 = create(:league_user, league: league, score: score)
    create(:pair, tournament: tournament, player1: lu1, player2: lu2)
  end

  describe "#call" do
    context "with 8 pairs, 2 groups, 4 to bracket" do
      before { 8.times { make_pair } }

      it "creates group-stage matches" do
        described_class.new(tournament).call
        expect(tournament.matches.group_stage.count).to be > 0
      end

      it "creates matches for both groups" do
        described_class.new(tournament).call
        expect(tournament.matches.group_stage.pluck(:group_number).uniq.sort).to eq([1, 2])
      end

      it "each group plays round-robin (4 pairs = 6 matches per group)" do
        described_class.new(tournament).call
        [1, 2].each do |g|
          expect(tournament.matches.group_stage.where(group_number: g).count).to eq(6)
        end
      end

      it "pre-creates bracket matches with no pairs assigned" do
        described_class.new(tournament).call
        bracket = tournament.matches.bracket
        expect(bracket.count).to be > 0
        expect(bracket.where(round_number: 1).all? { |m| m.pair1_id.nil? && m.pair2_id.nil? }).to be true
      end

      it "does not create loser bracket when loser_bracket is false" do
        described_class.new(tournament).call
        expect(tournament.matches.loser_bracket.count).to eq(0)
      end
    end

    context "with loser bracket enabled" do
      let(:tournament) do
        create(:tournament, :registration,
               type: :mixed,
               league: league,
               groups_count: 2,
               pairs_to_bracket: 2,
               loser_bracket: true)
      end

      before { 8.times { make_pair } }

      it "creates loser bracket slots" do
        described_class.new(tournament).call
        expect(tournament.matches.loser_bracket.count).to be > 0
      end
    end

    context "seeding: top pairs are placed as group seeds" do
      before do
        # Create high-score pair and lower-score pairs
        make_pair(score: 100)
        make_pair(score: 90)
        6.times { make_pair(score: 10) }
      end

      it "places the two highest-scored pairs into different groups" do
        pairs = tournament.pairs.sort_by(&:score).reverse
        top_two_ids = pairs.first(2).map(&:id)
        described_class.new(tournament).call

        group1_pair_ids = tournament.matches.group_stage.where(group_number: 1)
                                    .flat_map { |m| [m.pair1_id, m.pair2_id] }.compact.uniq
        group2_pair_ids = tournament.matches.group_stage.where(group_number: 2)
                                    .flat_map { |m| [m.pair1_id, m.pair2_id] }.compact.uniq

        expect(group1_pair_ids).to include(top_two_ids[0])
        expect(group2_pair_ids).to include(top_two_ids[1])
      end
    end
  end
end
