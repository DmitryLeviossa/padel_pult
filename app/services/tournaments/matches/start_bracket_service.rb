module Tournaments
  module Matches
    class StartBracketService
      def initialize(tournament)
        @tournament = tournament
      end

      def call
        return unless all_group_matches_completed?

        qualified_by_group, consolation_by_group = determine_pairs
        seed_stage(qualified_by_group, "bracket")

        if @tournament.loser_bracket?
          consolation = consolation_by_group.reject(&:empty?)
          seed_stage(consolation, "loser_bracket") if consolation.any?
        end
      end

      private

      def all_group_matches_completed?
        group_matches = @tournament.matches.group_stage
        group_matches.any? && !group_matches.pending.exists?
      end

      def determine_pairs
        qualifying_slots = @tournament.pairs_to_bracket
        qualified_by_group = []
        consolation_by_group = []

        (1..@tournament.groups_count).each do |group_num|
          standings = group_standings(group_num)
          qualified_by_group << standings.first(qualifying_slots)
          consolation_by_group << standings.drop(qualifying_slots)
        end

        [qualified_by_group, consolation_by_group]
      end

      def group_standings(group_num)
        matches = @tournament.matches.where(stage: "group", group_number: group_num, status: "completed")

        pair_ids = (matches.pluck(:pair1_id) + matches.pluck(:pair2_id)).compact.uniq
        pairs = @tournament.pairs.where(id: pair_ids)

        stats = pairs.map do |pair|
          wins = matches.where(winner_id: pair.id).count
          games_won = matches.where(pair1: pair).sum(:pair1_score) +
                      matches.where(pair2: pair).sum(:pair2_score)
          [pair, wins, games_won]
        end

        stats.sort_by { |_, wins, games| [-wins, -games] }.map(&:first)
      end

      # Seeds pairs from multiple groups into bracket slots so that same-group
      # pairs land in opposite SF halves and can only meet in the final.
      # When a group sends more pairs than can be perfectly separated (odd count),
      # pairs are placed as late as possible in the bracket.
      def seed_stage(groups_data, stage)
        all_pairs = groups_data.flatten.compact
        return if all_pairs.empty?

        n = next_power_of_two(all_pairs.length)
        slots = build_bracket_slots(groups_data, n)

        (n / 2).times do |i|
          pair1 = slots[i]
          pair2 = slots[n - 1 - i]
          is_bye = pair1.nil? || pair2.nil?

          match = @tournament.matches.find_by(
            stage: stage, group_number: 0, round_number: 1, position: i + 1
          )
          next unless match

          match.update!(
            pair1: pair1,
            pair2: pair2,
            winner: is_bye ? (pair1 || pair2) : nil,
            status: is_bye ? :bye : :pending
          )
        end

        @tournament.matches.where(stage: stage, status: "bye").each do |bye_match|
          Tournaments::Matches::AdvanceWinnerService.new(bye_match).call
        end
      end

      # Builds an n-slot array for the bracket. seeded[i] plays seeded[n-1-i] in R1.
      #
      # The bracket's two SF halves occupy non-contiguous index ranges:
      #   SF1: 0..n/4-1  and  3n/4..n-1
      #   SF2: n/4..n/2-1  and  n/2..3n/4-1
      #
      # For each group, pairs alternate between SF1 and SF2 based on
      # (group_index + rank_index).even? so that consecutive ranks from the
      # same group always land in opposite halves (meeting only in the final).
      # Byes fill the remaining nil slots naturally.
      def build_bracket_slots(groups_data, n)
        slots = Array.new(n, nil)

        sf1_pairs = []
        sf2_pairs = []

        groups_data.each_with_index do |group_pairs, g_idx|
          group_pairs.each_with_index do |pair, rank_idx|
            if (g_idx + rank_idx).even?
              sf1_pairs << pair
            else
              sf2_pairs << pair
            end
          end
        end

        sf1_slot_indices = (0...n / 4).to_a + (3 * n / 4...n).to_a.reverse
        sf2_slot_indices = (n / 4...n / 2).to_a + (n / 2...3 * n / 4).to_a.reverse

        fill_half(sf1_pairs, slots, sf1_slot_indices)
        fill_half(sf2_pairs, slots, sf2_slot_indices)

        slots
      end

      # Fills a bracket half's slots using Olympic seeding within the half:
      # best pairs take the "top" positions, second-best take "bottom" positions
      # counting inward, creating strongest-vs-weakest R1 matchups within the half.
      def fill_half(pairs, slots, slot_indices)
        half = slot_indices.length / 2
        pairs.each_with_index do |pair, i|
          idx = if i < half
                  slot_indices[i]
                else
                  slot_indices[slot_indices.length - 1 - (i - half)]
                end
          slots[idx] = pair
        end
      end

      def next_power_of_two(n)
        return 2 if n <= 2

        2**Math.log2(n).ceil
      end
    end
  end
end
