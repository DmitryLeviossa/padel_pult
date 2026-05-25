module Tournaments
  module Matches
    class StartBracketService
      def initialize(tournament)
        @tournament = tournament
      end

      def call
        return unless all_group_matches_completed?

        qualified_by_group, consolation_by_group = determine_pairs
        seed_stage(qualified_by_group, :bracket)

        if @tournament.loser_bracket?
          consolation = consolation_by_group.reject(&:empty?)
          seed_stage(consolation, :loser_bracket) if consolation.any?
        end
      end

      private

      def all_group_matches_completed?
        group_matches = @tournament.matches.group_stage.where.not(pair1_id: nil, pair2_id: nil)
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
        bracket = @tournament.brackets.group_stage.find_by!(group_number: group_num)
        matches = bracket.matches.completed

        pair_ids = (matches.pluck(:pair1_id) + matches.pluck(:pair2_id)).compact.uniq
        pairs = @tournament.pairs.where(id: pair_ids)

        stats = pairs.map do |pair|
          wins = matches.where(winner_id: pair.id).count
          games_won = matches.where(pair1: pair).sum(:pair1_score) +
                      matches.where(pair2: pair).sum(:pair2_score)
          [pair, wins, games_won]
        end

        stats.sort { |a, b| compare_standings(a, b, matches) }.map(&:first)
      end

      def compare_standings(a, b, matches)
        pair_a, wins_a, games_a = a
        pair_b, wins_b, games_b = b

        return wins_b <=> wins_a if wins_a != wins_b
        return games_b <=> games_a if games_a != games_b

        h2h = matches.find_by(pair1: pair_a, pair2: pair_b) ||
              matches.find_by(pair1: pair_b, pair2: pair_a)

        return 0 unless h2h&.winner_id

        h2h.winner_id == pair_a.id ? -1 : 1
      end

      def seed_stage(groups_data, bracket_type)
        all_pairs = groups_data.flatten.compact
        return if all_pairs.empty?

        n = next_power_of_two(all_pairs.length)
        slots = build_bracket_slots(groups_data, n)
        target_bracket = @tournament.brackets.find_by!(bracket_type: bracket_type, group_number: 0)

        (n / 2).times do |i|
          pair1 = slots[i]
          pair2 = slots[n - 1 - i]
          is_bye = pair1.nil? || pair2.nil?

          match = target_bracket.matches.find_by(round_number: 1, position: i + 1)
          next unless match

          match.update!(
            pair1: pair1,
            pair2: pair2,
            winner: is_bye ? (pair1 || pair2) : nil,
            status: is_bye ? :bye : :pending
          )
        end

        target_bracket.matches.bye.each do |bye_match|
          Tournaments::Matches::AdvanceWinnerService.new(bye_match).call
        end
      end

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
