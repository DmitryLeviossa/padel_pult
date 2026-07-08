module Tournaments
  class UpdatePlacementsService
    def initialize(tournament, placements = {})
      @tournament = tournament
      @placements = placements
    end

    def call
      ActiveRecord::Base.transaction do
        if @tournament.americano?
          update_americano
        else
          update_pairs_based
        end
      end
      true
    rescue ActiveRecord::RecordInvalid
      false
    end

    private

    def update_americano
      @tournament.tournament_participants.includes(:league_user).each do |participant|
        new_placement = @placements[participant.id.to_s].to_i
        next if new_placement < 1

        old_placement = participant.placement
        if old_placement && old_placement >= 1
          old_points = @tournament.points_for_place(old_placement)
          participant.league_user.decrement!(:score, old_points) if old_points > 0
        end

        new_points = @tournament.points_for_place(new_placement)
        participant.league_user.increment!(:score, new_points) if new_points > 0
        participant.update!(placement: new_placement)
      end
    end

    def update_pairs_based
      @tournament.pairs.each do |pair|
        new_placement = @placements[pair.id.to_s].to_i
        next if new_placement < 1

        old_placement = pair.placement
        if old_placement && old_placement >= 1
          old_points = @tournament.points_for_place(old_placement)
          if old_points > 0
            pair.player1.decrement!(:score, old_points) if pair.player1_count_score
            pair.player2.decrement!(:score, old_points) if pair.player2_count_score
          end
        end

        new_points = @tournament.points_for_place(new_placement)
        if new_points > 0
          pair.player1.increment!(:score, new_points) if pair.player1_count_score
          pair.player2.increment!(:score, new_points) if pair.player2_count_score
        end

        pair.update!(placement: new_placement)
      end
    end
  end
end
