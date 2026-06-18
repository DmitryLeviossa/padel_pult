module Tournaments
  module Matches
    # After an Americano match is saved, adds each pair's game points to the
    # individual TournamentParticipant totals. Both sides always earn points
    # (e.g., 17-15 → pair1 players each earn 17, pair2 players each earn 15).
    class AmericanoScoreService
      def initialize(match)
        @match = match
      end

      def call
        return unless @match.tournament.americano?
        return unless @match.completed?

        pair1_pts = @match.match_sets.sum(:pair1_score)
        pair2_pts = @match.match_sets.sum(:pair2_score)

        update_participants(@match.pair1, pair1_pts)
        update_participants(@match.pair2, pair2_pts)
      end

      private

      def update_participants(pair, points)
        return unless pair

        [ pair.player1_id, pair.player2_id ].each do |league_user_id|
          TournamentParticipant.find_by(
            tournament: @match.tournament,
            league_user_id: league_user_id
          )&.increment!(:total_score, points)
        end
      end
    end
  end
end
