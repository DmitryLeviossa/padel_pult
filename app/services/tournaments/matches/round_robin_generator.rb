module Tournaments
  module Matches
    class RoundRobinGenerator
      def initialize(tournament)
        @tournament = tournament
        @pairs = tournament.pairs.to_a
      end

      def call
        bracket = @tournament.brackets.find_or_create_by!(bracket_type: :bracket, group_number: 0)
        teams = @pairs.dup
        teams << nil if teams.length.odd?
        n = teams.length

        (n - 1).times do |round|
          (n / 2).times do |i|
            pair1 = teams[i]
            pair2 = teams[n - 1 - i]
            next if pair1.nil? || pair2.nil?

            bracket.matches.create!(
              tournament: @tournament,
              pair1: pair1,
              pair2: pair2,
              round_number: round + 1,
              position: i + 1,
              status: :pending
            )
          end

          teams = [ teams[0] ] + [ teams[-1] ] + teams[1...-1]
        end
      end
    end
  end
end
