# == Schema Information
#
# Table name: matches
#
#  id            :bigint           not null, primary key
#  group_number  :integer          default(0), not null
#  pair1_score   :integer
#  pair2_score   :integer
#  position      :integer          not null
#  round_number  :integer          not null
#  stage         :string           default("bracket"), not null
#  status        :string           default("pending"), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  pair1_id      :bigint
#  pair2_id      :bigint
#  tournament_id :bigint           not null
#  winner_id     :bigint
#
# Indexes
#
#  index_matches_on_pair1_id       (pair1_id)
#  index_matches_on_pair2_id       (pair2_id)
#  index_matches_on_tournament_id  (tournament_id)
#  index_matches_on_winner_id      (winner_id)
#  index_matches_uniqueness        (tournament_id,stage,group_number,round_number,position) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (pair1_id => pairs.id)
#  fk_rails_...  (pair2_id => pairs.id)
#  fk_rails_...  (tournament_id => tournaments.id)
#  fk_rails_...  (winner_id => pairs.id)
#
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
