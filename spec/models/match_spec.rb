# == Schema Information
#
# Table name: matches
#
#  id            :bigint           not null, primary key
#  pair1_score   :integer
#  pair2_score   :integer
#  position      :integer          not null
#  round_number  :integer          not null
#  status        :string           default("pending"), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  bracket_id    :bigint           not null
#  pair1_id      :bigint
#  pair2_id      :bigint
#  tournament_id :bigint           not null
#  winner_id     :bigint
#
# Indexes
#
#  index_matches_on_bracket_id     (bracket_id)
#  index_matches_on_pair1_id       (pair1_id)
#  index_matches_on_pair2_id       (pair2_id)
#  index_matches_on_tournament_id  (tournament_id)
#  index_matches_on_winner_id      (winner_id)
#  index_matches_uniqueness        (bracket_id,round_number,position) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (bracket_id => brackets.id)
#  fk_rails_...  (pair1_id => pairs.id)
#  fk_rails_...  (pair2_id => pairs.id)
#  fk_rails_...  (tournament_id => tournaments.id)
#  fk_rails_...  (winner_id => pairs.id)
#
require "rails_helper"

RSpec.describe Match, type: :model do
  describe "#third_place?" do
    def setup_third_place_matches(tournament)
      bracket = tournament.brackets.find_by!(bracket_type: "bracket", group_number: 0)
      bracket.matches.destroy_all
      final = bracket.matches.create!(tournament: tournament, round_number: 2, position: 1, status: :pending)
      third_place = bracket.matches.create!(tournament: tournament, round_number: 2, position: 2, status: :pending)
      semifinal = bracket.matches.create!(tournament: tournament, round_number: 1, position: 1, status: :pending)
      { bracket: bracket, final: final, third_place: third_place, semifinal: semifinal }
    end

    it "returns true for last-round position-2 match in bracket" do
      matches = setup_third_place_matches(create(:tournament))
      expect(matches[:third_place].third_place?).to be true
    end

    it "returns false for final match (position 1)" do
      matches = setup_third_place_matches(create(:tournament))
      expect(matches[:final].third_place?).to be false
    end

    it "returns false when not in last round" do
      matches = setup_third_place_matches(create(:tournament))
      expect(matches[:semifinal].third_place?).to be false
    end

    it "returns false for group stage match" do
      tournament = create(:tournament, groups_count: 1)
      group_bracket = tournament.brackets.find_or_create_by!(bracket_type: "group", group_number: 1)
      group_match = group_bracket.matches.create!(tournament: tournament, round_number: 1, position: 99, status: :pending)
      expect(group_match.third_place?).to be false
    end
  end

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
