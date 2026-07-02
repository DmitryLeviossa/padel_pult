require "rails_helper"

RSpec.describe Brackets::CreateGroupService do
  let(:league) { create(:league) }
  let(:tournament) { create(:tournament, :active, league: league) }

  def make_pair
    lu1 = create(:league_user, league: league)
    lu2 = create(:league_user, league: league)
    create(:pair, tournament: tournament, player1: lu1, player2: lu2)
  end

  describe "#call" do
    context "with fewer than 2 pairs" do
      it "returns a bracket with errors" do
        pair = make_pair
        result = described_class.new(tournament, { pair_ids: [ pair.id ], name: "G1", pairs_count: 1 }).call
        expect(result.errors[:base]).to include("Выберите не менее 2 пар")
      end

      it "does not create a bracket in the database" do
        pair = make_pair
        expect {
          described_class.new(tournament, { pair_ids: [ pair.id ], name: "G1", pairs_count: 1 }).call
        }.not_to change(Bracket, :count)
      end
    end

    context "with valid pairs" do
      let!(:pairs) { 4.times.map { make_pair } }

      it "creates a group_stage bracket" do
        expect {
          described_class.new(tournament, { pair_ids: pairs.map(&:id), name: "Group A", pairs_count: 4 }).call
        }.to change { tournament.brackets.group_stage.count }.by(1)
      end

      it "assigns sequential group_number" do
        described_class.new(tournament, { pair_ids: pairs.map(&:id), name: "Group A", pairs_count: 4 }).call
        described_class.new(tournament, { pair_ids: pairs.map(&:id), name: "Group B", pairs_count: 4 }).call
        group_numbers = tournament.brackets.group_stage.pluck(:group_number).sort
        expect(group_numbers).to eq([ 1, 2 ])
      end

      it "generates n*(n-1)/2 matches" do
        described_class.new(tournament, { pair_ids: pairs.map(&:id), name: "Group A", pairs_count: 4 }).call
        bracket = tournament.brackets.group_stage.last
        expect(bracket.matches.count).to eq(6)
      end

      it "each pair plays every other pair exactly once" do
        described_class.new(tournament, { pair_ids: pairs.map(&:id), name: "Group A", pairs_count: 4 }).call
        bracket = tournament.brackets.group_stage.last
        pairs.combination(2).each do |p1, p2|
          count = bracket.matches.where(
            "(pair1_id = ? AND pair2_id = ?) OR (pair1_id = ? AND pair2_id = ?)",
            p1.id, p2.id, p2.id, p1.id
          ).count
          expect(count).to eq(1)
        end
      end

      it "sets all matches to pending status" do
        described_class.new(tournament, { pair_ids: pairs.map(&:id), name: "Group A", pairs_count: 4 }).call
        bracket = tournament.brackets.group_stage.last
        expect(bracket.matches.pluck(:status).uniq).to eq([ "pending" ])
      end
    end

    context "with odd number of pairs" do
      let!(:pairs) { 3.times.map { make_pair } }

      it "generates n*(n-1)/2 matches (bye slots skipped)" do
        described_class.new(tournament, { pair_ids: pairs.map(&:id), name: "Group A", pairs_count: 3 }).call
        bracket = tournament.brackets.group_stage.last
        expect(bracket.matches.count).to eq(3)
      end
    end
  end
end
