class LeaguesController < ApplicationController
  def index
    @q = leagues_scope.ransack(params[:q])
    @leagues = @q.result
  end

  def show
    @league = League.find(params[:id])

    @q_members = @league.league_users.joins(:user).ransack(params[:q_members])
    @league_users = @q_members.result.includes(:user)
    if params[:members_status] == "pending"
      @league_users = @league_users.where.not(users: { invitation_token: nil })
    elsif params[:members_status] == "active"
      @league_users = @league_users.where(users: { invitation_token: nil })
    end
    @league_users = @league_users.order(score: :desc)

    if @league.owner == current_user
      excluded_ids = @league.user_ids + @league.league_invitations.pending.pluck(:invited_user_id)
      @invitable_users = User.where.not(id: excluded_ids).order(:first_name, :last_name)
      @league_members = @league.users.order(:first_name, :last_name)
      @league_telegram_setting = @league.league_telegram_setting || @league.build_league_telegram_setting
    end

    @settings_tab_active = params[:anchor] == "settings"
  end

  def new
    @league = League.new
  end

  def create
    @league = League.new(league_params)
    @league.owner = current_user

    if @league.save
      redirect_to leagues_path, notice: "Лига успешно создана."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def join
    @league = League.find(params[:id])
    if @league.users.include?(current_user)
      redirect_to @league, alert: "Вы уже являетесь участником этой лиги."
    else
      @league.league_users.create!(user: current_user)
      redirect_to @league, notice: "Вы вступили в лигу."
    end
  end

  def leave
    @league = League.find(params[:id])
    if @league.owner == current_user
      return redirect_to @league, alert: "Владелец не может покинуть лигу."
    end

    league_user = @league.league_users.find_by(user: current_user)
    if league_user
      league_user.destroy
      redirect_to @league, notice: "Вы покинули лигу."
    else
      redirect_to @league, alert: "Вы не являетесь участником этой лиги."
    end
  end

  def edit
    @league = League.find(params[:id])
    authorize_owner!
    redirect_to league_path(@league, anchor: "settings")
  end

  def update
    @league = League.find(params[:id])
    authorize_owner!

    if @league.update(league_params)
      redirect_to league_path(@league, anchor: "settings"), notice: "Лига обновлена."
    else
      load_show_resources
      @settings_tab_active = true
      render :show, status: :unprocessable_entity
    end
  end

  private

  def load_show_resources
    @q_members = @league.league_users.joins(:user).ransack(nil)
    @league_users = @q_members.result.includes(:user).order(score: :desc)
    if @league.owner == current_user
      excluded_ids = @league.user_ids + @league.league_invitations.pending.pluck(:invited_user_id)
      @invitable_users = User.where.not(id: excluded_ids).order(:first_name, :last_name)
      @league_members = @league.users.order(:first_name, :last_name)
      @league_telegram_setting = @league.league_telegram_setting || @league.build_league_telegram_setting
    end
  end

  def leagues_scope
    case params[:filter]
    when "all"
      League.all
    when "owned"
      League.where(owner: current_user)
    else
      member_ids = LeagueUser.where(user: current_user).select(:league_id)
      League.where(id: member_ids)
    end
  end

  def authorize_owner!
    redirect_to leagues_path, alert: "Нет доступа." unless @league.owner == current_user
  end

  def league_params
    params.require(:league).permit(:name, :description, :logo, :online_background, :owner_id, :tournaments_quota)
  end
end
