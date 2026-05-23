module Tournaments
  module Matches
    class AdvanceOlympicLoserService
      def initialize(match)
        @match = match
      end

      def call
        return unless @match.winner_id.present?
        return unless @match.bracket?
        return unless @match.round_number == 1
        return unless @match.tournament.loser_bracket?

        loser_id = @match.pair1_id == @match.winner_id ? @match.pair2_id : @match.pair1_id
        return unless loser_id.present?

        main_bracket = @match.tournament.brackets.bracket.first
        real_round1_positions = main_bracket&.matches
                                            &.where(round_number: 1)
                                            &.where.not(status: :bye)
                                            &.order(:position)
                                            &.pluck(:position) || []

        idx = real_round1_positions.index(@match.position)
        return unless idx

        lb = @match.tournament.brackets.loser_bracket.first
        lb_match = lb&.matches&.find_by(round_number: 1, position: idx / 2 + 1)
        return unless lb_match

        if idx.even?
          lb_match.update!(pair1_id: loser_id)
        else
          lb_match.update!(pair2_id: loser_id)
        end
      end
    end
  end
end
