class MatchesController < ApplicationController
  before_action :set_match
  before_action :authorize_tournament_owner!, except: :result_card

  def update
    if @match.has_downstream_results?
      redirect_to tournament_path(@match.tournament), alert: "Нельзя изменить результат: следующий матч уже завершён."
      return
    end

    was_completed = @match.completed?
    @match.match_sets.destroy_all if @match.tournament.sets_per_match > 1 && was_completed

    attrs, winner_id = build_match_attrs
    if @match.update(attrs.merge(status: :completed, winner_id: winner_id))
      if was_completed
        Tournaments::Matches::AdvanceWinnerService.new(@match).call if needs_winner_advance?
      else
        case @match.tournament.type
        when "olympic"
          Tournaments::Matches::AdvanceWinnerService.new(@match).call
          Tournaments::Matches::AdvanceLoserService.new(@match).call
          Tournaments::Matches::AdvanceOlympicLoserService.new(@match).call
        when "mixed"
          handle_mixed_match_completion
        end
      end
      broadcast_online_update
      redirect_to tournament_path(@match.tournament), notice: "Результат сохранён."
    else
      redirect_to tournament_path(@match.tournament), alert: "Не удалось сохранить результат."
    end
  end

  def result_card
    @pair1 = @match.pair1
    @pair2 = @match.pair2
    @match_sets = @match.match_sets.order(:set_number)
    render layout: false
  end

  def assign_pairs
    if @match.update(pair_assignment_params)
      redirect_to tournament_path(@match.tournament)
    else
      redirect_to tournament_path(@match.tournament), alert: "Не удалось обновить пары."
    end
  end

  private

  def needs_winner_advance?
    @match.tournament.olympic? || (@match.tournament.mixed? && @match.bracket?)
  end

  def broadcast_online_update
    tournament = @match.tournament
    data = Tournaments::MatchData.new(tournament)
    Turbo::StreamsChannel.broadcast_update_to(
      "tournament_#{tournament.id}_online",
      target: "tournament_matches",
      partial: "tournaments/online_matches",
      locals: data.to_locals
    )
  end

  def handle_mixed_match_completion
    if @match.group_stage?
      Tournaments::Matches::StartBracketService.new(@match.tournament).call
    else
      Tournaments::Matches::AdvanceWinnerService.new(@match).call
      Tournaments::Matches::AdvanceLoserService.new(@match).call
    end
  end

  def set_match
    @match = Match.includes(:tournament).find(params[:id])
  end

  def authorize_tournament_owner!
    unless @match.tournament.league.owner == current_user
      redirect_to tournament_path(@match.tournament), alert: "Нет доступа."
    end
  end

  def build_match_attrs
    if @match.tournament.sets_per_match > 1
      sets = match_params[:match_sets_attributes]&.values || []
      pair1_sets = sets.count { |s| s[:pair1_score].to_i > s[:pair2_score].to_i }
      pair2_sets = sets.count { |s| s[:pair2_score].to_i > s[:pair1_score].to_i }
      winner_id = pair1_sets >= pair2_sets ? @match.pair1_id : @match.pair2_id
      attrs = match_params.merge(pair1_score: pair1_sets, pair2_score: pair2_sets)
      [ attrs, winner_id ]
    else
      scores = match_params
      winner_id = scores[:pair1_score].to_i >= scores[:pair2_score].to_i ? @match.pair1_id : @match.pair2_id
      [ scores, winner_id ]
    end
  end

  def match_params
    params.require(:match).permit(
      :pair1_score, :pair2_score,
      match_sets_attributes: [ :set_number, :pair1_score, :pair2_score ]
    )
  end

  def pair_assignment_params
    params.require(:match).permit(:pair1_id, :pair2_id)
  end
end
