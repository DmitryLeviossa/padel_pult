require "rails_helper"

RSpec.describe Match, type: :model do
  describe "#sets_won_by_pair1" do
    it "counts sets where pair1 scored higher" do
      match = create(:match)
      create(:match_set, match: match, set_number: 1, pair1_score: 6, pair2_score: 4)
      create(:match_set, match: match, set_number: 2, pair1_score: 3, pair2_score: 6)
      create(:match_set, match: match, set_number: 3, pair1_score: 6, pair2_score: 2)

      expect(match.sets_won_by_pair1).to eq(2)
    end
  end

  describe "#sets_won_by_pair2" do
    it "counts sets where pair2 scored higher" do
      match = create(:match)
      create(:match_set, match: match, set_number: 1, pair1_score: 6, pair2_score: 4)
      create(:match_set, match: match, set_number: 2, pair1_score: 3, pair2_score: 6)
      create(:match_set, match: match, set_number: 3, pair1_score: 6, pair2_score: 2)

      expect(match.sets_won_by_pair2).to eq(1)
    end
  end

  describe "#sets_score_summary" do
    it "returns set scores as formatted string" do
      match = create(:match)
      create(:match_set, match: match, set_number: 1, pair1_score: 6, pair2_score: 4)
      create(:match_set, match: match, set_number: 2, pair1_score: 6, pair2_score: 3)

      expect(match.sets_score_summary).to eq("6:4, 6:3")
    end
  end
end
