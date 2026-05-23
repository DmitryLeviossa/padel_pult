module Tournaments
  module Matches
    class StructureGenerator
      def initialize(tournament)
        @tournament = tournament
      end

      def call
        @tournament.brackets.destroy_all
        case @tournament.type
        when "olympic"     then generate_olympic
        when "round_robin" then generate_round_robin
        when "mixed"       then generate_mixed
        end
      end

      private

      def generate_olympic
        n = next_power_of_two(@tournament.max_pairs)
        total_rounds = Math.log2(n).to_i
        bracket = @tournament.brackets.create!(bracket_type: :bracket, group_number: 0)

        (n / 2).times do |i|
          bracket.matches.create!(tournament: @tournament, round_number: 1, position: i + 1, status: :pending)
        end

        (2..total_rounds).each do |round|
          (n / (2**round)).times do |i|
            bracket.matches.create!(tournament: @tournament, round_number: round, position: i + 1, status: :pending)
          end
        end

        if total_rounds > 1
          bracket.matches.create!(tournament: @tournament, round_number: total_rounds, position: 2, status: :pending)
        end

        create_loser_bracket_structure(n) if @tournament.loser_bracket?
      end

      def create_loser_bracket_structure(main_n)
        loser_count = main_n / 2
        return if loser_count < 2

        loser_n = next_power_of_two(loser_count)
        loser_total_rounds = Math.log2(loser_n).to_i
        lb = @tournament.brackets.create!(bracket_type: :loser_bracket, group_number: 0)

        (loser_n / 2).times do |i|
          lb.matches.create!(tournament: @tournament, round_number: 1, position: i + 1, status: :pending)
        end

        (2..loser_total_rounds).each do |round|
          (loser_n / (2**round)).times do |i|
            lb.matches.create!(tournament: @tournament, round_number: round, position: i + 1, status: :pending)
          end
        end

        if loser_total_rounds > 1
          lb.matches.create!(tournament: @tournament, round_number: loser_total_rounds, position: 2, status: :pending)
        end
      end

      def generate_round_robin
        n = @tournament.max_pairs
        n += 1 if n.odd?
        bracket = @tournament.brackets.create!(bracket_type: :bracket, group_number: 0)

        (n - 1).times do |round_idx|
          (n / 2).times do |i|
            bracket.matches.create!(tournament: @tournament, round_number: round_idx + 1, position: i + 1, status: :pending)
          end
        end
      end

      def generate_mixed
        pairs_per_group = (@tournament.max_pairs.to_f / @tournament.groups_count).ceil
        n = pairs_per_group
        n += 1 if n.odd?

        @tournament.groups_count.times do |g|
          group_bracket = @tournament.brackets.create!(bracket_type: :group_stage, group_number: g + 1)
          (n - 1).times do |round_idx|
            (n / 2).times do |i|
              group_bracket.matches.create!(
                tournament: @tournament,
                round_number: round_idx + 1,
                position: i + 1,
                status: :pending
              )
            end
          end
        end

        pre_create_bracket(:bracket, @tournament.pairs_to_bracket)

        if @tournament.loser_bracket?
          non_qualifying = @tournament.max_pairs - @tournament.pairs_to_bracket
          pre_create_bracket(:loser_bracket, non_qualifying) if non_qualifying >= 2
        end
      end

      def pre_create_bracket(bracket_type, size)
        n = next_power_of_two(size)
        total_rounds = Math.log2(n).to_i
        bracket = @tournament.brackets.create!(bracket_type: bracket_type, group_number: 0)

        (1..total_rounds).each do |round|
          (n / (2**round)).times do |i|
            bracket.matches.create!(tournament: @tournament, round_number: round, position: i + 1, status: :pending)
          end
        end

        return unless total_rounds > 1

        bracket.matches.create!(tournament: @tournament, round_number: total_rounds, position: 2, status: :pending)
      end

      def next_power_of_two(n)
        return 2 if n <= 2
        2**Math.log2(n).ceil
      end
    end
  end
end
