class UsersController < ApplicationController
  before_action :set_user, only: [:show, :destroy, :invite]
  before_action :require_admin!, only: [:destroy, :invite]

  def index
    @q = User.ransack(params[:q])
    @users = @q.result.includes(leagues: { logo_attachment: :blob }).order(:last_name, :first_name, :email)
  end

  def show
    league_users = @user.league_users.includes(league: { logo_attachment: :blob })
    @league_user_ids = league_users.pluck(:id)

    @league_standings = league_users.map do |lu|
      ranked_ids = LeagueUser.where(league_id: lu.league_id).order(score: :desc).pluck(:id)
      position = ranked_ids.index(lu.id).to_i + 1
      { league: lu.league, league_user: lu, position: position, total: ranked_ids.count }
    end

    @tournament_pairs = Pair
      .includes(tournament: :league, player1: :user, player2: :user)
      .where("player1_id IN (?) OR player2_id IN (?)", @league_user_ids, @league_user_ids)
      .joins(:tournament)
      .order("tournaments.start_date DESC")

    pair_ids = @tournament_pairs.pluck(:id)

    @match_history = if pair_ids.any?
      Match
        .where("pair1_id IN (?) OR pair2_id IN (?)", pair_ids, pair_ids)
        .where.not(status: "pending")
        .includes(
          :tournament, :match_sets,
          pair1: [{ player1: :user }, { player2: :user }],
          pair2: [{ player1: :user }, { player2: :user }],
          result_card_image_attachment: :blob
        )
        .joins(:tournament)
        .order("tournaments.start_date DESC, matches.id DESC")
    else
      Match.none
    end
  end

  def destroy
    @user.destroy
    redirect_to users_path, notice: "Пользователь удалён."
  end

  def invite
    if @user.pending_invitation?
      redirect_to users_path, alert: "Пользователь уже приглашён."
    else
      @user.update!(invitation_token: SecureRandom.urlsafe_base64(32))
      redirect_to users_path, notice: "Приглашение создано. Скопируйте ссылку из карточки пользователя."
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def require_admin!
    redirect_to root_path, alert: "Нет доступа." unless current_user.id == 1
  end
end
