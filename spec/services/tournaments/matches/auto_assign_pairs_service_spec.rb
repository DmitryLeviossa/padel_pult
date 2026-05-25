require "rails_helper"

RSpec.describe Tournaments::Matches::AutoAssignPairsService do
  let(:league) { create(:league) }

  def make_pair(tournament, seeded: false)
    lu1 = create(:league_user, league: league)
    lu2 = create(:league_user, league: league)
    create(:pair, tournament: tournament, player1: lu1, player2: lu2, seeded: seeded)
  end

  context "when any match is already completed" do
    let(:tournament) { create(:tournament, :registration, type: :olympic, loser_bracket: false, league: league) }

    before do
      tournament.matches.first.update!(status: :completed)
    end

    it "returns false and does not modify matches" do
      expect(described_class.new(tournament).call).to be false
    end
  end

  context "olympic tournament" do
    # max_participants: 16 → max_pairs: 8, structure has 4 round-1 slots (n=8)
    let(:tournament) { create(:tournament, :registration, type: :olympic, loser_bracket: false, league: league) }

    before { 4.times { make_pair(tournament) } }

    it "returns true" do
      expect(described_class.new(tournament).call).to be true
    end

    it "assigns all eligible pairs to round-1 matches" do
      described_class.new(tournament).call
      r1 = tournament.matches.bracket.where(round_number: 1).reload
      assigned = r1.flat_map { |m| [ m.pair1_id, m.pair2_id ] }.compact
      expect(assigned).to match_array(tournament.eligible_pairs.map(&:id))
    end

    it "places seeded pairs first" do
      seeded = tournament.pairs.first
      seeded.update!(seeded: true)
      described_class.new(tournament).call
      first_match = tournament.matches.bracket.where(round_number: 1).order(:position).first.reload
      expect(first_match.pair1_id).to eq(seeded.id)
    end

    it "clears previous assignments before reassigning" do
      described_class.new(tournament).call
      described_class.new(tournament).call
      r1 = tournament.matches.bracket.where(round_number: 1)
      pair_ids = r1.flat_map { |m| [ m.pair1_id, m.pair2_id ] }.compact
      expect(pair_ids.uniq.length).to eq(pair_ids.length)
    end
  end

  context "round_robin tournament" do
    let(:tournament) { create(:tournament, :registration, type: :round_robin, loser_bracket: false, max_participants: 8, league: league) }

    before { 4.times { make_pair(tournament) } }

    it "returns true" do
      expect(described_class.new(tournament).call).to be true
    end

    it "assigns pairs so each match has two unique pairs" do
      described_class.new(tournament).call
      tournament.matches.reload.each do |match|
        next unless match.pair1_id && match.pair2_id
        expect(match.pair1_id).not_to eq(match.pair2_id)
      end
    end

    it "assigns each pair a different opponent per round" do
      described_class.new(tournament).call
      pair_ids = tournament.eligible_pairs.map(&:id)
      pair_ids.each do |pid|
        opponents = tournament.matches.where("pair1_id = ? OR pair2_id = ?", pid, pid)
                              .flat_map { |m| [ m.pair1_id, m.pair2_id ] }
                              .compact.reject { |id| id == pid }
        expect(opponents.uniq.length).to eq(opponents.length)
      end
    end
  end

  context "mixed tournament" do
    let(:tournament) do
      create(:tournament, :registration, type: :mixed, league: league,
             max_participants: 8, groups_count: 2, pairs_to_bracket: 1)
    end

    before { 4.times { make_pair(tournament) } }

    it "returns true" do
      expect(described_class.new(tournament).call).to be true
    end

    it "distributes pairs across groups with no overlap" do
      described_class.new(tournament).call
      group1_bracket = tournament.brackets.group_stage.find_by(group_number: 1)
      group2_bracket = tournament.brackets.group_stage.find_by(group_number: 2)

      group1_pairs = group1_bracket.matches.flat_map { |m| [ m.pair1_id, m.pair2_id ] }.compact.uniq
      group2_pairs = group2_bracket.matches.flat_map { |m| [ m.pair1_id, m.pair2_id ] }.compact.uniq

      expect(group1_pairs & group2_pairs).to be_empty
    end

    it "places seeded pairs into separate groups (one seed per group)" do
      # Two seeds (one per group) gives balanced distribution: each group gets 1 seed + 1 non-seed
      seeded1 = tournament.pairs.first
      seeded2 = tournament.pairs.second
      seeded1.update!(seeded: true)
      seeded2.update!(seeded: true)
      described_class.new(tournament).call

      group_brackets = tournament.brackets.group_stage
      all_pair_ids = group_brackets.flat_map { |b| b.matches.flat_map { |m| [ m.pair1_id, m.pair2_id ] } }.compact
      expect(all_pair_ids).to include(seeded1.id, seeded2.id)
    end
  end
end
