module Tournaments
  module Matches
    class StartBracketService
      def initialize(tournament)
        @tournament = tournament
      end

      def call
        return unless all_group_matches_completed?

        qualified, consolation = determine_pairs
        seed_stage(qualified, "bracket")
        seed_stage(consolation, "loser_bracket") if @tournament.loser_bracket? && consolation.any?
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

        [interleave_seeds(qualified_by_group), consolation_by_group.flatten.shuffle]
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

      # Interleave group finishes so group winners from different groups
      # are on opposite sides and can only meet in the final.
      # e.g. 2 groups sending 2 each: [G1-1st, G2-1st, G1-2nd, G2-2nd]
      # → Olympic seeding places G1-1st vs G2-2nd and G2-1st vs G1-2nd
      def interleave_seeds(groups)
        max_rank = groups.map(&:length).max
        interleaved = []
        max_rank.times do |rank|
          groups.each { |group| interleaved << group[rank] if rank < group.length }
        end
        interleaved
      end

      def seed_stage(pairs, stage)
        return if pairs.empty?

        n = next_power_of_two(pairs.length)
        seeded = pairs + [nil] * (n - pairs.length)

        (n / 2).times do |i|
          pair1 = seeded[i]
          pair2 = seeded[n - 1 - i]
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

      def next_power_of_two(n)
        return 2 if n <= 2
        2**Math.log2(n).ceil
      end
    end
  end
end
