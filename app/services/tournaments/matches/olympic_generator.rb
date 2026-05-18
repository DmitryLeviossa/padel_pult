module Tournaments
  module Matches
    class OlympicGenerator
      def initialize(tournament)
        @tournament = tournament
      end

      def call
        pairs = @tournament.pairs.sort_by(&:score).reverse
        n = next_power_of_two(pairs.length)
        seeded = pairs + ([ nil ] * (n - pairs.length))

        total_rounds = Math.log2(n).to_i

        # Round 1: seed by score (top seed vs last slot, etc.)
        (n / 2).times do |i|
          pair1 = seeded[i]
          pair2 = seeded[n - 1 - i]
          is_bye = pair1.nil? || pair2.nil?

          @tournament.matches.create!(
            pair1: pair1,
            pair2: pair2,
            winner: is_bye ? (pair1 || pair2) : nil,
            round_number: 1,
            position: i + 1,
            status: is_bye ? :bye : :pending
          )
        end

        # Pre-create empty matches for subsequent rounds
        (2..total_rounds).each do |round|
          count = n / (2 ** round)
          count.times do |i|
            @tournament.matches.create!(
              round_number: round,
              position: i + 1,
              status: :pending
            )
          end
        end

        # 3rd place match (between semifinal losers) when bracket has at least 2 rounds
        if total_rounds > 1
          @tournament.matches.create!(
            round_number: total_rounds,
            position: 2,
            status: :pending
          )
        end

        # Immediately advance bye winners into the bracket
        @tournament.matches.bye.each do |bye_match|
          Tournaments::Matches::AdvanceWinnerService.new(bye_match).call
        end
      end

      private

      def next_power_of_two(n)
        return 2 if n <= 2
        2 ** Math.log2(n).ceil
      end
    end
  end
end
