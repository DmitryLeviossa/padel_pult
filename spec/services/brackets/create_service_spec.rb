require "rails_helper"

RSpec.describe Brackets::CreateService do
  let(:league) { create(:league) }
  let(:tournament) { create(:tournament, :registration, type: :olympic, league: league) }

  before { tournament.brackets.destroy_all }

  def call(params)
    described_class.new(tournament, params).call
  end

  context "with valid params" do
    it "creates a bracket with the given name and pairs_count" do
      bracket = call(name: "Group A", pairs_count: 4)
      expect(bracket).to be_persisted
      expect(bracket.name).to eq("Group A")
      expect(bracket.pairs_count).to eq(4)
      expect(bracket.bracket_type).to eq("bracket")
    end

    it "auto-increments group_number based on existing brackets" do
      call(name: "First", pairs_count: 4)
      bracket2 = call(name: "Second", pairs_count: 4)
      expect(bracket2.group_number).to eq(2)
    end

    it "generates matches for 2 pairs (1 round-1 match, no third-place when single round)" do
      bracket = call(name: "Test", pairs_count: 2)
      expect(bracket.matches.where(round_number: 1).count).to eq(1)
      expect(bracket.matches.count).to eq(1)
    end

    it "generates matches for 4 pairs" do
      bracket = call(name: "Test", pairs_count: 4)
      expect(bracket.matches.where(round_number: 1).count).to eq(2)
      expect(bracket.matches.where(round_number: 2).count).to eq(2)
    end

    it "generates matches for 8 pairs" do
      bracket = call(name: "Test", pairs_count: 8)
      expect(bracket.matches.where(round_number: 1).count).to eq(4)
      expect(bracket.matches.where(round_number: 2).count).to eq(2)
      expect(bracket.matches.where(round_number: 3).count).to eq(2)
    end

    it "rounds up to next power of two (5 pairs treated as 8)" do
      bracket = call(name: "Test", pairs_count: 5)
      expect(bracket.matches.where(round_number: 1).count).to eq(4)
    end
  end

  context "with invalid params" do
    it "returns an unsaved bracket when validation fails" do
      bracket = call(name: nil, pairs_count: 4)
      expect(bracket).not_to be_persisted
    end

    it "does not create any matches when bracket is invalid" do
      expect { call(name: nil, pairs_count: 4) }.not_to change(Match, :count)
    end
  end
end
