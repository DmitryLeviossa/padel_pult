module Tournaments
  module Matches
    class RoundRobinGenerator
      def initialize(tournament)
        @tournament = tournament
        @pairs = tournament.pairs.to_a
      end

      def call
        teams = @pairs.dup
        teams << nil if teams.length.odd?
        n = teams.length

        (n - 1).times do |round|
          (n / 2).times do |i|
            pair1 = teams[i]
            pair2 = teams[n - 1 - i]
            next if pair1.nil? || pair2.nil?

            @tournament.matches.create!(
              pair1: pair1,
              pair2: pair2,
              round_number: round + 1,
              position: i + 1,
              status: :pending
            )
          end

          # Circle method: keep first fixed, rotate the rest right by one
          teams = [ teams[0] ] + [ teams[-1] ] + teams[1...-1]
        end
      end
    end
  end
end
