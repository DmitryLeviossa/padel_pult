module Tournaments
  module Matches
    class AdvanceWinnerService
      def initialize(match)
        @match = match
      end

      def call
        return unless @match.winner_id.present?
        return if @match.group_stage?

        parent = @match.tournament.matches.find_by(
          stage: @match.stage,
          group_number: @match.group_number,
          round_number: @match.round_number + 1,
          position: ((@match.position.to_f) / 2).ceil
        )
        return unless parent

        if @match.position.odd?
          parent.update!(pair1_id: @match.winner_id)
        else
          parent.update!(pair2_id: @match.winner_id)
        end
      end
    end
  end
end
