module Tournaments
  class CompleteService
    def initialize(tournament, placements = {})
      @tournament = tournament
      @placements = placements
    end

    def call
      ActiveRecord::Base.transaction do
        if @tournament.americano?
          complete_americano
        else
          complete_pairs_based
        end

        @tournament.completed!
      end
      true
    rescue ActiveRecord::RecordInvalid
      false
    end

    private

    def complete_americano
      sorted = @tournament.tournament_participants
                          .order(total_score: :desc, created_at: :asc)
                          .to_a

      sorted.each_with_index do |participant, i|
        placement = i + 1
        participant.update!(placement: placement)
        points = @tournament.points_for_place(placement)
        participant.league_user.increment!(:score, points) if points > 0
      end
    end

    def complete_pairs_based
      @tournament.pairs.each do |pair|
        placement = @placements[pair.id.to_s].to_i
        next if placement < 1

        pair.update!(placement: placement)
        points = @tournament.points_for_place(placement)
        pair.player1.increment!(:score, points)
        pair.player2.increment!(:score, points)
      end
    end
  end
end
