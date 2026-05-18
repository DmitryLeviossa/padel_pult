class MatchesController < ApplicationController
  before_action :set_match
  before_action :authorize_tournament_owner!

  def update
    scores = match_params
    winner_id = scores[:pair1_score].to_i >= scores[:pair2_score].to_i ? @match.pair1_id : @match.pair2_id
    if @match.update(scores.merge(status: :completed, winner_id: winner_id))
      if @match.tournament.olympic?
        Tournaments::Matches::AdvanceWinnerService.new(@match).call
        Tournaments::Matches::AdvanceLoserService.new(@match).call
      end
      redirect_to tournament_path(@match.tournament), notice: t(".success")
    else
      redirect_to tournament_path(@match.tournament), alert: t(".failure")
    end
  end

  private

  def set_match
    @match = Match.includes(:tournament).find(params[:id])
  end

  def authorize_tournament_owner!
    unless @match.tournament.league.owner == current_user
      redirect_to tournament_path(@match.tournament), alert: t("not_authorized")
    end
  end

  def match_params
    params.require(:match).permit(:pair1_score, :pair2_score)
  end
end
