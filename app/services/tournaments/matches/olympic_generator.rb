module Tournaments
  module Matches
    class OlympicGenerator
      def initialize(tournament)
        @tournament = tournament
      end

      def call
        pairs = @tournament.pairs.to_a
        n = next_power_of_two(pairs.length)
        seeded_pairs = pairs.select(&:seeded)
        non_seeded_pairs = pairs.reject(&:seeded)
        ordered = seeded_pairs + non_seeded_pairs
        seeded = ordered + ([ nil ] * (n - ordered.length))

        total_rounds = Math.log2(n).to_i
        bracket = @tournament.brackets.find_or_create_by!(bracket_type: :bracket, group_number: 0)

        (n / 2).times do |i|
          pair1 = seeded[i]
          pair2 = seeded[n - 1 - i]
          is_bye = pair1.nil? || pair2.nil?

          bracket.matches.create!(
            tournament: @tournament,
            pair1: pair1,
            pair2: pair2,
            winner: is_bye ? (pair1 || pair2) : nil,
            round_number: 1,
            position: i + 1,
            status: is_bye ? :bye : :pending
          )
        end

        (2..total_rounds).each do |round|
          count = n / (2 ** round)
          count.times do |i|
            bracket.matches.create!(
              tournament: @tournament,
              round_number: round,
              position: i + 1,
              status: :pending
            )
          end
        end

        if total_rounds > 1
          bracket.matches.create!(
            tournament: @tournament,
            round_number: total_rounds,
            position: 2,
            status: :pending
          )
        end

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
        lb = @tournament.brackets.find_or_create_by!(bracket_type: :loser_bracket, group_number: 0)

        (loser_n / 2).times do |i|
          lb.matches.create!(
            tournament: @tournament,
            round_number: 1,
            position: i + 1,
            status: :pending
          )
        end

        (2..loser_total_rounds).each do |round|
          count = loser_n / (2 ** round)
          count.times do |i|
            lb.matches.create!(
              tournament: @tournament,
              round_number: round,
              position: i + 1,
              status: :pending
            )
          end
        end

        if loser_total_rounds > 1
          lb.matches.create!(
            tournament: @tournament,
            round_number: loser_total_rounds,
            position: 2,
            status: :pending
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
