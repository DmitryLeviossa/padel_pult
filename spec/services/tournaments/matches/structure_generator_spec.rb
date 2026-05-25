require "rails_helper"

RSpec.describe Tournaments::Matches::StructureGenerator do
  let(:league) { create(:league) }

  def run(tournament)
    tournament.brackets.destroy_all
    described_class.new(tournament).call
  end

  context "olympic tournament" do
    let(:tournament) { create(:tournament, :registration, type: :olympic, loser_bracket: false, max_participants: 8, league: league) }

    it "creates one bracket" do
      run(tournament)
      expect(tournament.brackets.count).to eq(1)
    end

    it "generates correct match structure for 4 pairs (next power of 2 = 4)" do
      run(tournament)
      bracket = tournament.brackets.first
      expect(bracket.matches.where(round_number: 1).count).to eq(2)
      expect(bracket.matches.where(round_number: 2).count).to eq(2)
    end

    it "includes a third-place match in the final round" do
      run(tournament)
      bracket = tournament.brackets.first
      total_rounds = bracket.matches.maximum(:round_number)
      expect(bracket.matches.find_by(round_number: total_rounds, position: 2)).to be_present
    end

    it "all matches start as pending" do
      run(tournament)
      expect(tournament.matches.all? { |m| m.status == "pending" }).to be true
    end

    context "with loser_bracket enabled" do
      let(:tournament) { create(:tournament, :registration, type: :olympic, loser_bracket: true, max_participants: 8, league: league) }

      it "creates a main bracket and a loser bracket" do
        run(tournament)
        expect(tournament.brackets.where(bracket_type: :bracket).count).to eq(1)
        expect(tournament.brackets.where(bracket_type: :loser_bracket).count).to eq(1)
      end

      it "creates matches in the loser bracket" do
        run(tournament)
        expect(tournament.matches.loser_bracket.count).to be > 0
      end
    end
  end

  context "round_robin tournament" do
    let(:tournament) { create(:tournament, :registration, type: :round_robin, loser_bracket: false, max_participants: 8, league: league) }

    it "creates one bracket" do
      run(tournament)
      expect(tournament.brackets.count).to eq(1)
    end

    it "generates (n-1) rounds with n/2 matches each for 4 pairs" do
      run(tournament)
      bracket = tournament.brackets.first
      expect(bracket.matches.select(:round_number).distinct.count).to eq(3)
      expect(bracket.matches.where(round_number: 1).count).to eq(2)
    end

    it "generates rounds for odd max_pairs (padded to next even)" do
      tournament.update_column(:max_participants, 6)
      run(tournament)
      bracket = tournament.brackets.first
      expect(bracket.matches.select(:round_number).distinct.count).to eq(3)
    end
  end

  context "mixed tournament" do
    let(:tournament) do
      create(:tournament, :registration, type: :mixed, league: league,
             max_participants: 8, groups_count: 2, pairs_to_bracket: 1)
    end

    it "creates group_stage brackets for each group" do
      run(tournament)
      expect(tournament.brackets.group_stage.count).to eq(2)
    end

    it "creates a main bracket for the knockout stage" do
      run(tournament)
      expect(tournament.brackets.where(bracket_type: :bracket).count).to eq(1)
    end

    it "destroys all existing brackets before generating" do
      run(tournament)
      old_count = tournament.brackets.count
      run(tournament)
      expect(tournament.brackets.count).to eq(old_count)
    end

    context "with loser_bracket enabled" do
      let(:tournament) do
        create(:tournament, :registration, type: :mixed, league: league,
               max_participants: 8, groups_count: 2, pairs_to_bracket: 1, loser_bracket: true)
      end

      it "creates a loser bracket" do
        run(tournament)
        expect(tournament.brackets.where(bracket_type: :loser_bracket).count).to eq(1)
      end
    end
  end
end
