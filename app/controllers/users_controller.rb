class UsersController < ApplicationController
  def index
    @q = User.ransack(params[:q])
    @users = @q.result.includes(leagues: { logo_attachment: :blob }).order(:last_name, :first_name, :email)
  end

  def show
    @user = User.find(params[:id])
    league_user_ids = @user.league_users.pluck(:id)
    @tournament_pairs = Pair
      .includes(tournament: :league, player1: :user, player2: :user)
      .where("player1_id IN (?) OR player2_id IN (?)", league_user_ids, league_user_ids)
      .joins(:tournament)
      .order("tournaments.start_date DESC")
    @league_user_ids = league_user_ids
  end
end
