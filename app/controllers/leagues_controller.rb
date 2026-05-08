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

  private

  def league_params
    params.require(:league).permit(:name, :description)
  end
end
