module Tournaments
  module Matches
    # Generates the full round schedule for Americano tournaments.
    #
    # rounds_count = number of full rotation cycles.
    # One cycle = n-1 rotations of the circle (all player slots, including bye nils).
    # Courts are formed from consecutive groups of 4; courts with a bye slot are skipped.
    # All valid matches within a single cycle share the same round_number.
    # This guarantees each player partners with every other player once per cycle.
    class AmericanoGenerator
      def initialize(tournament)
        @tournament = tournament
        @participants = tournament.tournament_participants.includes(:league_user).to_a
      end

      def call
        return if @participants.size < 4

        players = @participants.dup
        players << nil while players.size % 4 != 0

        n = players.size
        bracket = @tournament.brackets.create!(bracket_type: :bracket, group_number: 0)

        @tournament.rounds_count.times do |cycle|
          round_number = cycle + 1
          position = 0
          circle = players.dup

          (n - 1).times do
            courts_this_round = courts_for(circle, n)

            courts_this_round.each do |team|
              position += 1
              pair1 = @tournament.pairs.create!(player1: team[0].league_user, player2: team[1].league_user)
              pair2 = @tournament.pairs.create!(player1: team[2].league_user, player2: team[3].league_user)
              bracket.matches.create!(
                tournament: @tournament,
                pair1: pair1,
                pair2: pair2,
                round_number: round_number,
                position: position,
                status: :pending
              )
            end

            circle = [circle[0]] + [circle[-1]] + circle[1...-1]
          end
        end
      end

      private

      def courts_for(circle, n)
        courts = []
        (n / 4).times do |court_idx|
          team = circle.slice(4 * court_idx, 4)
          courts << team unless team.any?(&:nil?)
        end
        courts
      end
    end
  end
end
