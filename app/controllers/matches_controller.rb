class MatchesController < ApplicationController
  before_action :set_match, except: :create
  before_action :set_tournament, only: :create
  before_action :authorize_tournament_owner!, except: :result_card
  before_action :ensure_tournament_not_completed!, except: :result_card
  skip_before_action :authenticate_user!, only: :result_card

  def create
    service = Tournaments::Matches::AddMatchService.new(@tournament, params[:round_number])
    if service.call
      broadcast_online_update_for(@tournament)
      redirect_to tournament_path(@tournament), notice: "Матч добавлен."
    else
      redirect_to tournament_path(@tournament), alert: service.errors.to_sentence.presence || "Не удалось добавить матч."
    end
  end

  def update
    if @match.has_downstream_results?
      redirect_to tournament_path(@match.tournament), alert: "Нельзя изменить результат: следующий матч уже завершён."
      return
    end

    was_completed = @match.completed?
    @match.match_sets.destroy_all if was_completed

    attrs, winner_id = build_match_attrs
    if @match.update(attrs.merge(status: :completed, winner_id: winner_id))
      if was_completed
        Tournaments::Matches::AdvanceWinnerService.new(@match).call if needs_winner_advance?
        Tournaments::Matches::StartBracketService.new(@match.tournament).call if @match.tournament.mixed? && @match.group_stage?
        recalculate_americano_scores if @match.tournament.americano?
      else
        case @match.tournament.type
        when "olympic"
          Tournaments::Matches::AdvanceWinnerService.new(@match).call
          Tournaments::Matches::AdvanceLoserService.new(@match).call
          Tournaments::Matches::AdvanceOlympicLoserService.new(@match).call
        when "mixed"
          handle_mixed_match_completion
        when "americano"
          Tournaments::Matches::AmericanoScoreService.new(@match).call
        end
      end
      broadcast_online_update
      generate_result_card_image
      redirect_to tournament_path(@match.tournament), notice: "Результат сохранён."
    else
      redirect_to tournament_path(@match.tournament), alert: "Не удалось сохранить результат."
    end
  end

  def result_card
    unless @match.completed? && @match.pair1.present? && @match.pair2.present?
      raise ActiveRecord::RecordNotFound
    end

    @pair1 = @match.pair1
    @pair2 = @match.pair2
    @match_sets = @match.match_sets.order(:set_number)
    render layout: false
  end

  def finish
    if @match.completed? || @match.bye? || (@match.pair1.present? && @match.pair2.present?)
      redirect_to tournament_path(@match.tournament), alert: "Этот матч нельзя завершить таким способом."
      return
    end

    winner_id = @match.pair1_id || @match.pair2_id
    if @match.update(status: :completed, winner_id: winner_id)
      case @match.tournament.type
      when "olympic"
        Tournaments::Matches::AdvanceWinnerService.new(@match).call
        Tournaments::Matches::AdvanceLoserService.new(@match).call
        Tournaments::Matches::AdvanceOlympicLoserService.new(@match).call
      when "mixed"
        handle_mixed_match_completion
      end
      broadcast_online_update
      generate_result_card_image
      redirect_to tournament_path(@match.tournament), notice: "Матч завершён."
    else
      redirect_to tournament_path(@match.tournament), alert: "Не удалось завершить матч."
    end
  end

  def destroy
    tournament = @match.tournament
    removable = @match.third_place? || tournament.round_robin?

    unless removable
      redirect_to tournament_path(tournament), alert: "Этот матч нельзя удалить."
      return
    end

    notice = @match.third_place? ? "Матч за 3-е место удалён." : "Матч удалён."
    @match.destroy
    broadcast_online_update_for(tournament)
    redirect_to tournament_path(tournament), notice: notice
  end

  def assign_pairs
    if @match.update(pair_assignment_params)
      redirect_to tournament_path(@match.tournament)
    else
      redirect_to tournament_path(@match.tournament), alert: @match.errors.full_messages.to_sentence.presence || "Не удалось обновить пары."
    end
  end

  private

  def generate_result_card_image
    match_id = @match.id
    Thread.new do
      ActiveRecord::Base.connection_pool.with_connection do
        GenerateMatchResultCardJob.perform_now(match_id)
      end
    rescue => e
      Rails.logger.error "GenerateMatchResultCardJob failed for match #{match_id}: #{e.message}"
    end
  end

  def needs_winner_advance?
    @match.tournament.olympic? || (@match.tournament.mixed? && @match.bracket?)
  end

  def broadcast_online_update
    broadcast_online_update_for(@match.tournament)
  end

  def broadcast_online_update_for(tournament)
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

  def recalculate_americano_scores
    tournament = @match.tournament
    tournament.tournament_participants.update_all(total_score: 0)
    tournament.matches.completed.each do |m|
      Tournaments::Matches::AmericanoScoreService.new(m).call
    end
  end

  def set_match
    @match = Match.includes(:tournament).find(params[:id])
  end

  def set_tournament
    @tournament = Tournament.find(params[:tournament_id])
  end

  def tournament
    @match&.tournament || @tournament
  end

  def ensure_tournament_not_completed!
    if tournament.completed?
      redirect_to tournament_path(tournament), alert: "Нельзя изменить результат: турнир завершён."
    end
  end

  def authorize_tournament_owner!
    unless tournament.league.owner == current_user
      redirect_to tournament_path(tournament), alert: "Нет доступа."
    end
  end

  def build_match_attrs
    sets = match_params[:match_sets_attributes]&.values || []

    if @match.tournament.americano?
      pair1_total = sets.sum { |s| s[:pair1_score].to_i }
      pair2_total = sets.sum { |s| s[:pair2_score].to_i }
      winner_id = pair1_total >= pair2_total ? @match.pair1_id : @match.pair2_id
      attrs = match_params.merge(pair1_score: pair1_total, pair2_score: pair2_total)
    else
      pair1_sets = sets.count { |s| s[:pair1_score].to_i > s[:pair2_score].to_i }
      pair2_sets = sets.count { |s| s[:pair2_score].to_i > s[:pair1_score].to_i }
      winner_id = pair1_sets >= pair2_sets ? @match.pair1_id : @match.pair2_id
      attrs = match_params.merge(pair1_score: pair1_sets, pair2_score: pair2_sets)
    end

    [ attrs, winner_id ]
  end

  def match_params
    params.require(:match).permit(
      match_sets_attributes: [ :set_number, :pair1_score, :pair2_score ]
    )
  end

  def pair_assignment_params
    params.require(:match).permit(:pair1_id, :pair2_id)
  end
end
