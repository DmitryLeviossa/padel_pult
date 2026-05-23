require "rails_helper"

RSpec.describe Tournaments::Matches::StartBracketService do
  let(:league) { create(:league) }
  let(:tournament) do
    create(:tournament, :active,
           type: :mixed,
           league: league,
           groups_count: 2,
           pairs_to_bracket: 4,
           loser_bracket: false)
  end

  # Creates 4 pairs per group with given scores, generates group matches,
  # then records results so standings are deterministic.
  def setup_groups_with_results
    pairs = []
    2.times do |g|
      4.times do |i|
        lu1 = create(:league_user, league: league)
        lu2 = create(:league_user, league: league)
        pairs << create(:pair, tournament: tournament, player1: lu1, player2: lu2)
      end
    end
    tournament.reload

    Tournaments::Matches::MixedGenerator.new(tournament).call

    # Complete all group matches: pair1 always wins with a higher score
    tournament.matches.group_stage.each do |m|
      m.update!(status: :completed, pair1_score: 6, pair2_score: 3, winner_id: m.pair1_id)
    end

    pairs
  end

  describe "#call" do
    context "after all group matches are completed" do
      before { setup_groups_with_results }

      it "fills round-1 bracket slots with pairs" do
        described_class.new(tournament).call
        r1 = tournament.matches.bracket.where(round_number: 1)
        expect(r1.all? { |m| m.pair1_id.present? || m.pair2_id.present? }).to be true
      end

      it "assigns pairs from different groups to the same bracket match" do
        described_class.new(tournament).call
        r1 = tournament.matches.bracket.where(round_number: 1)
        # Each match should have both pair1 and pair2 (no byes expected with 4 exact pairs)
        r1.each do |m|
          expect(m.pair1_id).to be_present
          expect(m.pair2_id).to be_present
        end
      end

      it "does not re-run if called twice" do
        described_class.new(tournament).call
        bracket_pairs_first = tournament.matches.bracket.where(round_number: 1).map { |m| [m.pair1_id, m.pair2_id] }
        described_class.new(tournament).call
        bracket_pairs_second = tournament.matches.bracket.where(round_number: 1).map { |m| [m.pair1_id, m.pair2_id] }
        expect(bracket_pairs_first).to eq(bracket_pairs_second)
      end
    end

    context "when group matches are not yet all complete" do
      before do
        Tournaments::Matches::MixedGenerator.new(tournament).call
        # Leave one group match pending
        tournament.matches.group_stage.first(5).each do |m|
          m.update!(status: :completed, pair1_score: 6, pair2_score: 3, winner_id: m.pair1_id)
        end
      end

      it "does not fill bracket slots" do
        described_class.new(tournament).call
        r1 = tournament.matches.bracket.where(round_number: 1)
        expect(r1.all? { |m| m.pair1_id.nil? && m.pair2_id.nil? }).to be true
      end
    end

    context "with unequal group sizes (13 pairs, 4 groups, 2 per group to bracket)" do
      let(:tournament) do
        create(:tournament, :active,
               type: :mixed,
               league: league,
               groups_count: 4,
               pairs_to_bracket: 2,
               loser_bracket: false)
      end

      before do
        13.times do
          lu1 = create(:league_user, league: league)
          lu2 = create(:league_user, league: league)
          create(:pair, tournament: tournament, player1: lu1, player2: lu2)
        end
        tournament.reload
        Tournaments::Matches::MixedGenerator.new(tournament).call
        tournament.matches.group_stage.each do |m|
          m.update!(status: :completed, pair1_score: 6, pair2_score: 3, winner_id: m.pair1_id)
        end
      end

      it "seeds bracket with pairs_to_bracket pairs per group (2 per group × 4 groups = 8 total)" do
        described_class.new(tournament).call
        seeded = tournament.matches.bracket.where(round_number: 1)
                           .flat_map { |m| [m.pair1_id, m.pair2_id] }.compact
        expect(seeded.uniq.count).to eq(8)
      end
    end

    context "with 3 groups × 2 advancing (6 pairs in 8-slot bracket)" do
      let(:tournament) do
        create(:tournament, :active,
               type: :mixed,
               league: league,
               groups_count: 3,
               pairs_to_bracket: 2,
               loser_bracket: false)
      end

      before do
        # Assign pairs to groups manually: 2 pairs per group (exact pairs_to_bracket)
        3.times do
          2.times do
            lu1 = create(:league_user, league: league)
            lu2 = create(:league_user, league: league)
            create(:pair, tournament: tournament, player1: lu1, player2: lu2)
          end
        end
        tournament.reload
        Tournaments::Matches::MixedGenerator.new(tournament).call
        tournament.matches.group_stage.each do |m|
          m.update!(status: :completed, pair1_score: 6, pair2_score: 3, winner_id: m.pair1_id)
        end
      end

      it "never places same-group pairs against each other in round 1" do
        described_class.new(tournament).call

        r1 = tournament.matches.bracket.where(round_number: 1, status: :pending)
        r1.each do |match|
          next unless match.pair1_id && match.pair2_id

          group1 = tournament.matches.group_stage
                             .where("pair1_id = ? OR pair2_id = ?", match.pair1_id, match.pair1_id)
                             .pick(:group_number)
          group2 = tournament.matches.group_stage
                             .where("pair1_id = ? OR pair2_id = ?", match.pair2_id, match.pair2_id)
                             .pick(:group_number)
          expect(group1).not_to eq(group2), "R1 match #{match.id} pairs from same group #{group1}"
        end
      end

      it "places same-group pairs in opposite bracket halves so they can meet in the final" do
        described_class.new(tournament).call

        n = tournament.matches.bracket.where(round_number: 1).count * 2
        r1 = tournament.matches.bracket.where(round_number: 1).order(:position)

        # Build a map: pair_id → which SF half it belongs to
        # SF1 = positions 1..n/4, SF2 = positions n/4+1..n/2
        sf1_pairs = Set.new
        sf2_pairs = Set.new

        r1.each do |match|
          half = match.position <= n / 4 ? :sf1 : :sf2
          sf1_pairs << match.pair1_id if match.pair1_id && half == :sf1
          sf1_pairs << match.pair2_id if match.pair2_id && half == :sf1
          sf2_pairs << match.pair1_id if match.pair1_id && half == :sf2
          sf2_pairs << match.pair2_id if match.pair2_id && half == :sf2
        end

        (1..tournament.groups_count).each do |group_num|
          group_pair_ids = tournament.matches
                                     .where(group_number: group_num, stage: "group")
                                     .flat_map { |m| [m.pair1_id, m.pair2_id] }.compact.uniq
          qualified = group_pair_ids.select { |id| sf1_pairs.include?(id) || sf2_pairs.include?(id) }
          next if qualified.length < 2

          in_sf1 = qualified.count { |id| sf1_pairs.include?(id) }
          in_sf2 = qualified.count { |id| sf2_pairs.include?(id) }
          expect(in_sf1).to eq(1), "Group #{group_num}: expected 1 pair in SF1 half, got #{in_sf1}"
          expect(in_sf2).to eq(1), "Group #{group_num}: expected 1 pair in SF2 half, got #{in_sf2}"
        end
      end
    end

    context "with loser bracket enabled" do
      let(:tournament) do
        create(:tournament, :active,
               type: :mixed,
               league: league,
               groups_count: 2,
               pairs_to_bracket: 2,
               loser_bracket: true)
      end

      before { setup_groups_with_results }

      it "seeds the loser bracket with non-qualifying pairs" do
        described_class.new(tournament).call
        loser_r1 = tournament.matches.loser_bracket.where(round_number: 1)
        expect(loser_r1.any? { |m| m.pair1_id.present? || m.pair2_id.present? }).to be true
      end
    end
  end
end
