module Tournaments
  module Matches
    class AdvanceLoserService
      def initialize(match)
        @match = match
      end

      def call
        return unless @match.winner_id.present?

        bracket_matches = @match.tournament.matches.where(stage: @match.stage, group_number: 0)
        total_rounds = bracket_matches.maximum(:round_number)
        return unless @match.round_number == total_rounds - 1

        third_place = bracket_matches.find_by(round_number: total_rounds, position: 2)
        return unless third_place

        loser_id = @match.pair1_id == @match.winner_id ? @match.pair2_id : @match.pair1_id

        if @match.position.odd?
          third_place.update!(pair1_id: loser_id)
        else
          third_place.update!(pair2_id: loser_id)
        end
      end
    end
  end
end
