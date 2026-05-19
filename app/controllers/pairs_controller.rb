class PairsController < ApplicationController
  before_action :set_tournament
  before_action :authorize_league_member!, only: :create, unless: :owner_adding_pair?
  before_action :authorize_registration_open!, only: :create
  before_action :authorize_not_already_registered!, only: :create, unless: :owner_adding_pair?
  before_action :authorize_owner_for_pair_add!, only: :create, if: :owner_adding_pair?
  before_action :set_pair, only: :destroy
  before_action :authorize_league_owner!, only: :destroy

  def create
    if owner_adding_pair?
      player1 = @tournament.league.league_users.find(params.dig(:pair, :player1_id))
      player2 = @tournament.league.league_users.find(params.dig(:pair, :player2_id))
      @pair = @tournament.pairs.build(player1: player1, player2: player2)
    else
      @pair = @tournament.pairs.build(player1: current_league_user, player2: partner)
    end

    if @pair.save
      notify_partner unless owner_adding_pair?
      redirect_to tournament_path(@tournament)
    else
      redirect_to tournament_path(@tournament)
    end
  end

  def destroy
    @pair.destroy
    redirect_to tournament_path(@tournament), notice: t(".success")
  end

  private

  def set_tournament
    @tournament = Tournament.find(params[:tournament_id])
  end

  def set_pair
    @pair = @tournament.pairs.find(params[:id])
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

  def notify_partner
    partner_user = partner.user
    return if partner_user == current_user

    Notification.create!(
      user: partner_user,
      notification_type: :tournament_added,
      message: t("pairs.notifications.tournament_added",
                 tournament: @tournament.name,
                 league: @tournament.league.name,
                 inviter: current_user.full_name),
      url: tournament_path(@tournament)
    )
  end

  def authorize_league_owner!
    unless @tournament.league.owner == current_user && @tournament.registration?
      redirect_to tournament_path(@tournament), alert: t("pairs.delete_not_allowed")
    end
  end

  def owner_adding_pair?
    params.dig(:pair, :player1_id).present?
  end

  def authorize_owner_for_pair_add!
    unless @tournament.league.owner == current_user
      redirect_to tournament_path(@tournament), alert: t("pairs.not_authorized")
    end
  end
end
