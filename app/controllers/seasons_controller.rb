class SeasonsController < ApplicationController
  before_action :set_league
  before_action :set_season, only: [:show, :edit, :update, :destroy]
  before_action :authorize_owner!, only: [:new, :create, :edit, :update, :destroy]

  def show
    @tournaments = @league.tournaments
      .where(start_date: @season.date_from..@season.date_to)
      .order(start_date: :asc)

    tournaments = @tournaments.completed

    pairs = Pair.where(tournament: tournaments)
      .where.not(placement: nil)
      .includes(:tournament)

    points_by_user = Hash.new(0)
    pairs.each do |pair|
      pts = pair.tournament.points_for_place(pair.placement)
      next if pts.zero?
      points_by_user[pair.player1_id] += pts
      points_by_user[pair.player2_id] += pts
    end

    @rankings = LeagueUser.where(id: points_by_user.keys)
      .includes(:user)
      .sort_by { |lu| -points_by_user[lu.id] }
      .map { |lu| { league_user: lu, points: points_by_user[lu.id] } }
  end

  def new
    @season = @league.seasons.new
  end

  def create
    @season = @league.seasons.new(season_params)
    if @season.save
      redirect_to league_season_path(@league, @season), notice: "Сезон создан."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @season.update(season_params)
      redirect_to league_season_path(@league, @season), notice: "Сезон обновлён."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @season.destroy
    redirect_to league_path(@league, anchor: "seasons"), notice: "Сезон удалён."
  end

  private

  def set_league
    @league = League.find(params[:league_id])
  end

  def set_season
    @season = @league.seasons.find(params[:id])
  end

  def authorize_owner!
    redirect_to league_path(@league), alert: "Нет доступа." unless @league.owner == current_user
  end

  def season_params
    params.require(:season).permit(:name, :date_from, :date_to, :description, :logo)
  end
end
