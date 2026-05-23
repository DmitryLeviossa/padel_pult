class BracketsController < ApplicationController
  before_action :set_tournament
  before_action :authorize_owner!

  def new
    @bracket = Bracket.new
  end

  def create
    @bracket = Brackets::CreateService.new(@tournament, bracket_params).call

    if @bracket.persisted?
      redirect_to tournament_path(@tournament, anchor: "bracket-#{@bracket.id}"), notice: "Сетка создана."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_tournament
    @tournament = Tournament.find(params[:tournament_id])
  end

  def authorize_owner!
    redirect_to tournament_path(@tournament), alert: "Нет доступа." unless @tournament.league.owner == current_user
  end

  def bracket_params
    params.require(:bracket).permit(:name, :pairs_count)
  end
end
