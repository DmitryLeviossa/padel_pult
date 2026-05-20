class Leagues::LeagueUsersController < ApplicationController
  before_action :set_league
  before_action :authorize_owner!

  def edit
    @league_user = @league.league_users.find(params[:id])
    redirect_to league_path(@league, anchor: "league-users") unless @league_user.user.pending_invitation?
  end

  def update
    @league_user = @league.league_users.find(params[:id])

    if params[:user]
      unless @league_user.user.pending_invitation?
        return redirect_to league_path(@league, anchor: "league-users"), alert: "Этот участник уже зарегистрировался и не может быть изменён."
      end
      @league_user.user.update!(user_params)
      redirect_to league_path(@league, anchor: "league-users"), notice: "Имя участника обновлено."
    else
      @league_user.update!(score: params[:league_user][:score].to_i)
      head :ok
    end
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    @user.email = "invited_#{SecureRandom.hex(10)}@padelpult.invited"
    @user.password = SecureRandom.hex(16)
    @user.invitation_token = SecureRandom.urlsafe_base64(32)

    User.transaction do
      @user.save!
      @league.league_users.create!(user: @user)
    end

    redirect_to league_path(@league, anchor: "league-users"), notice: "Участник добавлен. Скопируйте ссылку для приглашения из списка участников."
  rescue ActiveRecord::RecordInvalid
    render :new, status: :unprocessable_entity
  end

  private

  def set_league
    @league = League.find(params[:league_id])
  end

  def authorize_owner!
    redirect_to leagues_path, alert: "Нет доступа." unless @league.owner == current_user
  end

  def user_params
    params.require(:user).permit(:first_name, :last_name, :gender)
  end
end
