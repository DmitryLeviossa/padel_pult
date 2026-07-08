module Tournaments
  module Matches
    class MixedGenerator
      def initialize(tournament)
        @tournament = tournament
      end

      def call
        seed_and_create_groups
        total_qualifying = @tournament.pairs_to_bracket * @tournament.groups_count
        pre_create_bracket(:bracket, total_qualifying)
        if @tournament.loser_bracket?
          non_qualifying = @tournament.pairs.count - total_qualifying
          pre_create_bracket(:loser_bracket, non_qualifying) if non_qualifying >= 2
        end
      end

      private

      def seed_and_create_groups
        pairs = @tournament.pairs.to_a
        groups = distribute_to_groups(pairs)
        groups.each_with_index { |group_pairs, i| generate_group_matches(group_pairs, i + 1) }
      end

      def distribute_to_groups(pairs)
        count = @tournament.groups_count
        groups = Array.new(count) { [] }
        seeded = pairs.select(&:seeded)
        non_seeded = pairs.reject(&:seeded)
        seeds = seeded.first(count)
        remaining = (seeded.drop(count) + non_seeded).shuffle
        seeds.each_with_index { |seed, i| groups[i] << seed }
        offset = seeds.length
        remaining.each_with_index { |pair, i| groups[(i + offset) % count] << pair }
        groups
      end

      def generate_group_matches(pairs, group_number)
        bracket = @tournament.brackets.find_or_create_by!(bracket_type: :group_stage, group_number: group_number)
        list = pairs.dup
        list << nil if list.length.odd?
        n = list.length

        (n - 1).times do |round_idx|
          (n / 2).times do |i|
            pair1 = list[i]
            pair2 = list[n - 1 - i]
            next if pair1.nil? || pair2.nil?

            bracket.matches.create!(
              tournament: @tournament,
              pair1: pair1,
              pair2: pair2,
              round_number: round_idx + 1,
              position: i + 1,
              status: :pending
            )
          end

          list = [list[0]] + [list[n - 1]] + list[1..n - 2]
        end
      end

      def pre_create_bracket(bracket_type, size)
        n = next_power_of_two(size)
        total_rounds = Math.log2(n).to_i
        bracket = @tournament.brackets.find_or_create_by!(bracket_type: bracket_type, group_number: 0)

        (1..total_rounds).each do |round|
          (n / (2**round)).times do |i|
            bracket.matches.create!(
              tournament: @tournament,
              round_number: round,
              position: i + 1,
              status: :pending
            )
          end
        end

        return unless total_rounds > 1

        bracket.matches.create!(
          tournament: @tournament,
          round_number: total_rounds,
          position: 2,
          status: :pending
        )
      end

      def next_power_of_two(n)
        return 2 if n <= 2
        2**Math.log2(n).ceil
      end
    end
  end
end
