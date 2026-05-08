class TournamentsController < ApplicationController
  before_action :set_league, only: [:new, :create]
  before_action :set_tournament, only: [:show]
  before_action :authorize_owner!, only: [:new, :create]

  def index
    @tournaments = Tournament.all
  end

  def show
  end

  def new
    @tournament = @league.tournaments.build
  end

  def create
    @tournament = @league.tournaments.build(tournament_params)

    if @tournament.save
      redirect_to league_path(@league), notice: "Tournament created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_league
    @league = League.find(params[:league_id])
  end

  def set_tournament
    @tournament = Tournament.includes(pairs: [:player1, :player2]).find(params[:id])
  end

  def authorize_owner!
    redirect_to league_path(@league), alert: "Not authorized." unless @league.owner == current_user
  end

  def tournament_params
    params.require(:tournament).permit(:name, :start_date, :end_date, :max_participants, :location, :type, :description)
  end
end
