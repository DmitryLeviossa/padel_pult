class LeaguesController < ApplicationController
  def index
    @q = leagues_scope.ransack(params[:q])
    @leagues = @q.result
  end

  def show
    @league = League.find(params[:id])
    if @league.owner == current_user
      excluded_ids = @league.user_ids + @league.league_invitations.pending.pluck(:invited_user_id)
      @invitable_users = User.where.not(id: excluded_ids).order(:first_name, :last_name)
    end
  end

  def new
    @league = League.new
  end

  def create
    @league = League.new(league_params)
    @league.owner = current_user

    if @league.save
      redirect_to leagues_path, notice: "League created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def join
    @league = League.find(params[:id])
    if @league.users.include?(current_user)
      redirect_to @league, alert: t("leagues.show.already_member")
    else
      @league.league_users.create!(user: current_user)
      redirect_to @league, notice: t("leagues.show.joined")
    end
  end

  def leave
    @league = League.find(params[:id])
    if @league.owner == current_user
      return redirect_to @league, alert: t("leagues.show.owner_cannot_leave")
    end

    league_user = @league.league_users.find_by(user: current_user)
    if league_user
      league_user.destroy
      redirect_to @league, notice: t("leagues.show.left")
    else
      redirect_to @league, alert: t("leagues.show.not_member")
    end
  end

  def edit
    @league = League.find(params[:id])
    authorize_owner!
    @league_members = @league.users.order(:first_name, :last_name)
  end

  def update
    @league = League.find(params[:id])
    authorize_owner!

    if @league.update(league_params)
      redirect_to @league, notice: "Лига обновлена."
    else
      @league_members = @league.users.order(:first_name, :last_name)
      render :edit, status: :unprocessable_entity
    end
  end

  private

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
    params.require(:league).permit(:name, :description, :logo, :owner_id)
  end
end
