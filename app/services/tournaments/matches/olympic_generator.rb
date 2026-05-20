module Tournaments
  module Matches
    class OlympicGenerator
      def initialize(tournament)
        @tournament = tournament
      end

      def call
        pairs = @tournament.eligible_pairs
        n = next_power_of_two(pairs.length)
        seeded_pairs = pairs.select(&:seeded)
        non_seeded_pairs = pairs.reject(&:seeded)
        ordered = seeded_pairs + non_seeded_pairs
        seeded = ordered + ([ nil ] * (n - ordered.length))

        total_rounds = Math.log2(n).to_i

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

        create_loser_bracket(pairs.length, n) if @tournament.loser_bracket?
      end

      private

      def create_loser_bracket(pair_count, n)
        loser_count = pair_count - n / 2
        return if loser_count < 2

        loser_n = next_power_of_two(loser_count)
        loser_total_rounds = Math.log2(loser_n).to_i

        (loser_n / 2).times do |i|
          @tournament.matches.create!(
            round_number: 1,
            position: i + 1,
            status: :pending,
            stage: :loser_bracket
          )
        end

        (2..loser_total_rounds).each do |round|
          count = loser_n / (2 ** round)
          count.times do |i|
            @tournament.matches.create!(
              round_number: round,
              position: i + 1,
              status: :pending,
              stage: :loser_bracket
            )
          end
        end

        if loser_total_rounds > 1
          @tournament.matches.create!(
            round_number: loser_total_rounds,
            position: 2,
            status: :pending,
            stage: :loser_bracket
          )
        end
      end

      def next_power_of_two(n)
        return 2 if n <= 2
        2 ** Math.log2(n).ceil
      end
    end
  end
end
