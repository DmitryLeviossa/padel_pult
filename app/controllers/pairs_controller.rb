class PairsController < ApplicationController
  before_action :set_tournament
  before_action :authorize_league_member!
  before_action :authorize_registration_open!
  before_action :authorize_not_already_registered!

  def create
    @pair = @tournament.pairs.build(player1: current_league_user, player2: partner)
    if @pair.save
      redirect_to tournament_path(@tournament), notice: t(".success")
    else
      redirect_to tournament_path(@tournament), alert: t(".failure")
    end
  end

  private

  def set_tournament
    @tournament = Tournament.find(params[:tournament_id])
  end

  def current_league_user
    @current_league_user ||= @tournament.league.league_users.find_by!(user: current_user)
  end

  def partner
    @partner ||= @tournament.league.league_users.find(params.dig(:pair, :player2_id))
  end

  def authorize_league_member!
    @tournament.league.league_users.find_by!(user: current_user)
  rescue ActiveRecord::RecordNotFound
    redirect_to tournament_path(@tournament), alert: t("pairs.not_league_member")
  end

  def authorize_registration_open!
    unless @tournament.registration?
      redirect_to tournament_path(@tournament), alert: t("pairs.registration_closed")
    end
  end

  def authorize_not_already_registered!
    league_user = current_league_user
    already_in = @tournament.pairs.exists?(player1_id: league_user.id) ||
                 @tournament.pairs.exists?(player2_id: league_user.id)
    if already_in
      redirect_to tournament_path(@tournament), alert: t("pairs.already_registered")
    end
  end
end
