class Leagues::LeagueUsersController < ApplicationController
  before_action :set_league
  before_action :authorize_owner!

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

    redirect_to league_path(@league), notice: t(".success")
  rescue ActiveRecord::RecordInvalid
    render :new, status: :unprocessable_entity
  end

  private

  def set_league
    @league = League.find(params[:league_id])
  end

  def authorize_owner!
    redirect_to leagues_path, alert: t("leagues.show.not_authorized") unless @league.owner == current_user
  end

  def user_params
    params.require(:user).permit(:first_name, :last_name, :gender)
  end
end
