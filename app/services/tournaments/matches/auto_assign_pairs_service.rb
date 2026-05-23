module Tournaments
  module Matches
    class AutoAssignPairsService
      def initialize(tournament)
        @tournament = tournament
      end

      def call
        return false if @tournament.matches.completed.any?

        ActiveRecord::Base.transaction do
          @tournament.matches.update_all(pair1_id: nil, pair2_id: nil, winner_id: nil, status: "pending")

          case @tournament.type
          when "olympic"     then assign_olympic
          when "round_robin" then assign_round_robin
          when "mixed"       then assign_mixed
          end
        end

        true
      rescue => e
        Rails.logger.error("AutoAssignPairsService failed: #{e.message}")
        false
      end

      private

      def assign_olympic
        pairs = @tournament.eligible_pairs
        return if pairs.empty?

        n = next_power_of_two(@tournament.max_pairs)
        ordered = pairs.select(&:seeded) + pairs.reject(&:seeded)
        seeded = ordered + ([ nil ] * (n - ordered.length))

        @tournament.matches.bracket.where(round_number: 1).order(:position).each_with_index do |match, i|
          match.update!(pair1: seeded[i], pair2: seeded[n - 1 - i])
        end
      end

      def assign_round_robin
        pairs = @tournament.eligible_pairs
        return if pairs.empty?

        teams = pairs.dup
        teams << nil if teams.length.odd?
        n = teams.length

        (n - 1).times do |round_idx|
          (n / 2).times do |i|
            pair1 = teams[i]
            pair2 = teams[n - 1 - i]
            next if pair1.nil? || pair2.nil?

            match = @tournament.matches.find_by(round_number: round_idx + 1, position: i + 1)
            match&.update!(pair1: pair1, pair2: pair2)
          end

          teams = [ teams[0] ] + [ teams[-1] ] + teams[1...-1]
        end
      end

      def assign_mixed
        pairs = @tournament.eligible_pairs
        return if pairs.empty?

        distribute_to_groups(pairs).each_with_index { |group_pairs, i| assign_group_matches(group_pairs, i + 1) }
      end

      def distribute_to_groups(pairs)
        count = @tournament.groups_count
        groups = Array.new(count) { [] }
        seeded = pairs.select(&:seeded)
        non_seeded = pairs.reject(&:seeded)
        seeds = seeded.first(count)
        remaining = (seeded.drop(count) + non_seeded).shuffle
        seeds.each_with_index { |seed, i| groups[i] << seed }
        remaining.each_with_index { |pair, i| groups[i % count] << pair }
        groups
      end

      def assign_group_matches(pairs, group_number)
        bracket = @tournament.brackets.group_stage.find_by!(group_number: group_number)
        list = pairs.dup
        list << nil if list.length.odd?
        n = list.length

        (n - 1).times do |round_idx|
          (n / 2).times do |i|
            pair1 = list[i]
            pair2 = list[n - 1 - i]
            next if pair1.nil? || pair2.nil?

            match = bracket.matches.find_by(round_number: round_idx + 1, position: i + 1)
            match&.update!(pair1: pair1, pair2: pair2)
          end

          list = [ list[0] ] + [ list[-1] ] + list[1...-1]
        end
      end

      def next_power_of_two(n)
        return 2 if n <= 2
        2**Math.log2(n).ceil
      end
    end
  end
end
