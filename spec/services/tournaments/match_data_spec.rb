require "rails_helper"

RSpec.describe Tournaments::MatchData do
  let(:league) { create(:league) }

  def make_pair(tournament)
    lu1 = create(:league_user, league: league)
    lu2 = create(:league_user, league: league)
    create(:pair, tournament: tournament, player1: lu1, player2: lu2)
  end

  describe "#to_locals" do
    let(:tournament) { create(:tournament, :registration, type: :olympic, league: league) }

    it "returns a hash with the expected keys" do
      keys = described_class.new(tournament).to_locals.keys
      expect(keys).to contain_exactly(
        :tournament, :matches, :bracket_rounds,
        :third_place_match, :group_data,
        :loser_bracket_rounds, :loser_third_place_match,
        :custom_bracket_data, :custom_group_data, :result_card_matches
      )
    end
  end

  describe "olympic tournament" do
    let(:tournament) { create(:tournament, :registration, type: :olympic, loser_bracket: false, league: league) }

    before do
      tournament.brackets.destroy_all
      4.times { make_pair(tournament) }
      Tournaments::Matches::OlympicGenerator.new(tournament).call
    end

    it "populates bracket_rounds" do
      data = described_class.new(tournament)
      expect(data.bracket_rounds).not_to be_empty
    end

    it "extracts the third_place_match from the final round" do
      data = described_class.new(tournament)
      expect(data.third_place_match).to be_present
      expect(data.third_place_match.position).to eq(2)
    end

    it "does not populate group_data" do
      data = described_class.new(tournament)
      expect(data.group_data).to be_nil
    end

    it "does not populate loser_bracket_rounds" do
      data = described_class.new(tournament)
      expect(data.loser_bracket_rounds).to be_nil
    end
  end

  describe "mixed tournament" do
    let(:tournament) do
      create(:tournament, :registration, type: :mixed, league: league,
             max_participants: 8, groups_count: 2, pairs_to_bracket: 1)
    end

    before do
      tournament.brackets.destroy_all
      4.times { make_pair(tournament) }
      Tournaments::Matches::MixedGenerator.new(tournament).call
    end

    it "populates group_data with one entry per group" do
      data = described_class.new(tournament)
      expect(data.group_data.length).to eq(2)
    end

    it "populates bracket_rounds for the knockout stage" do
      data = described_class.new(tournament)
      expect(data.bracket_rounds).not_to be_nil
    end

    it "includes pairs_ordered in each group entry" do
      data = described_class.new(tournament)
      data.group_data.each do |g|
        expect(g).to have_key(:pairs_ordered)
      end
    end
  end
end
