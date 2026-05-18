module Tournaments
  class CompleteService
    def initialize(tournament, placements)
      @tournament = tournament
      @placements = placements
    end

    def call
      ActiveRecord::Base.transaction do
        @tournament.pairs.each do |pair|
          placement = @placements[pair.id.to_s].to_i
          next if placement < 1

          pair.update!(placement: placement)
          points = @tournament.points_for_place(placement)
          pair.player1.increment!(:score, points)
          pair.player2.increment!(:score, points)
        end

        @tournament.completed!
      end
      true
    rescue ActiveRecord::RecordInvalid
      false
    end
  end
end
