class LeaguesController < ApplicationController
  def index
    @leagues = League.all
  end

  def show
    @league = League.find(params[:id])
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

  def edit
    @league = League.find(params[:id])
    authorize_owner!
  end

  def update
    @league = League.find(params[:id])
    authorize_owner!

    if @league.update(league_params)
      redirect_to @league, notice: "Лига обновлена."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def authorize_owner!
    redirect_to leagues_path, alert: "Нет доступа." unless @league.owner == current_user
  end

  def league_params
    params.require(:league).permit(:name, :description, :logo)
  end
end
