require "rails_helper"

RSpec.describe Tournaments::Matches::ManualAssignPairsService do
  let(:league) { create(:league) }

  def make_pair(tournament, seeded: false)
    lu1 = create(:league_user, league: league)
    lu2 = create(:league_user, league: league)
    create(:pair, tournament: tournament, player1: lu1, player2: lu2, seeded: seeded)
  end

  let(:tournament) do
    create(:tournament, :registration, type: :mixed, league: league,
           max_participants: 8, groups_count: 2, pairs_to_bracket: 1)
  end

  let!(:pairs) { Array.new(4) { make_pair(tournament) } }

  def assignments_for(group1_pairs:, group2_pairs:)
    group1_pairs.each_with_object({}) { |p, h| h[p.id] = 1 }
                .merge(group2_pairs.each_with_object({}) { |p, h| h[p.id] = 2 })
  end

  context "when any match is already completed" do
    before { tournament.matches.first.update!(status: :completed) }

    it "returns false and records an error" do
      service = described_class.new(tournament, assignments_for(group1_pairs: pairs[0..1], group2_pairs: pairs[2..3]))
      expect(service.call).to be false
      expect(service.errors).to be_present
    end
  end

  context "when not all pairs are assigned" do
    it "returns false" do
      service = described_class.new(tournament, { pairs[0].id => 1 })
      expect(service.call).to be false
      expect(service.errors).to include(match(/распределить все пары/))
    end
  end

  context "when a group number is out of range" do
    it "returns false" do
      assignments = assignments_for(group1_pairs: pairs[0..1], group2_pairs: pairs[2..3])
      assignments[pairs[3].id] = 3
      service = described_class.new(tournament, assignments)
      expect(service.call).to be false
      expect(service.errors).to include(match(/Некорректный номер группы/))
    end
  end

  context "when group sizes don't match the current distribution" do
    it "returns false" do
      # first run auto-assign equivalent to establish a 2/2 split, then try an uneven 3/1 split
      service = described_class.new(tournament, assignments_for(group1_pairs: pairs[0..1], group2_pairs: pairs[2..3]))
      expect(service.call).to be true

      uneven = assignments_for(group1_pairs: pairs[0..2], group2_pairs: pairs[3..3])
      service2 = described_class.new(tournament, uneven)
      expect(service2.call).to be false
      expect(service2.errors).to include(match(/должно совпадать с текущим распределением/))
    end
  end

  context "with a valid even split on a fresh tournament (no prior assignment)" do
    it "returns true and assigns pairs to the requested groups" do
      service = described_class.new(tournament, assignments_for(group1_pairs: pairs[0..1], group2_pairs: pairs[2..3]))
      expect(service.call).to be true

      group1_bracket = tournament.brackets.group_stage.find_by(group_number: 1)
      group2_bracket = tournament.brackets.group_stage.find_by(group_number: 2)

      group1_pair_ids = group1_bracket.matches.flat_map { |m| [ m.pair1_id, m.pair2_id ] }.compact.uniq
      group2_pair_ids = group2_bracket.matches.flat_map { |m| [ m.pair1_id, m.pair2_id ] }.compact.uniq

      expect(group1_pair_ids).to match_array(pairs[0..1].map(&:id))
      expect(group2_pair_ids).to match_array(pairs[2..3].map(&:id))
    end
  end

  context "when re-assigning pairs after a previous manual assignment" do
    it "swaps pairs between groups while keeping group sizes fixed" do
      described_class.new(tournament, assignments_for(group1_pairs: pairs[0..1], group2_pairs: pairs[2..3])).call

      swapped = assignments_for(group1_pairs: [ pairs[0], pairs[2] ], group2_pairs: [ pairs[1], pairs[3] ])
      service = described_class.new(tournament, swapped)
      expect(service.call).to be true

      group1_bracket = tournament.brackets.group_stage.find_by(group_number: 1)
      group1_pair_ids = group1_bracket.matches.flat_map { |m| [ m.pair1_id, m.pair2_id ] }.compact.uniq
      expect(group1_pair_ids).to match_array([ pairs[0].id, pairs[2].id ])
    end

    it "clears stale matches from the previous distribution" do
      described_class.new(tournament, assignments_for(group1_pairs: pairs[0..1], group2_pairs: pairs[2..3])).call

      swapped = assignments_for(group1_pairs: [ pairs[0], pairs[2] ], group2_pairs: [ pairs[1], pairs[3] ])
      described_class.new(tournament, swapped).call

      group2_bracket = tournament.brackets.group_stage.find_by(group_number: 2)
      group2_pair_ids = group2_bracket.matches.flat_map { |m| [ m.pair1_id, m.pair2_id ] }.compact.uniq
      expect(group2_pair_ids).not_to include(pairs[2].id)
    end
  end
end
