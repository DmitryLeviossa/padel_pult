class TournamentsController < ApplicationController
  before_action :set_league, only: [ :new, :create ]
  before_action :set_tournament, only: [ :show, :open_registration ]
  before_action :authorize_owner!, only: [ :new, :create ]
  before_action :authorize_tournament_owner!, only: [ :open_registration ]

  def index
    filter_params = params[:q]&.to_unsafe_h || {}
    filter_params[:status_in] = %w[registration active] if filter_params[:status_in].blank?
    @q = Tournament.where.not(status: :draft).ransack(filter_params)
    @tournaments = @q.result.includes(:pairs)
  end

  def show
    @sort = params[:sort].presence_in(%w[score player1 player2 player1_score player2_score created_at]) || "score"
    @direction = params[:direction].presence_in(%w[asc desc]) || "desc"

    sorted = @tournament.pairs.sort_by do |pair|
      case @sort
      when "player1"       then pair.player1.full_name
      when "player2"       then pair.player2.full_name
      when "player1_score" then pair.player1.score
      when "player2_score" then pair.player2.score
      when "created_at"    then pair.created_at
      else                      pair.score
      end
    end

    @pairs = @direction == "desc" ? sorted.reverse : sorted
  end

  def new
    @tournament = @league.tournaments.build
    @tournament.placement_points = [
      { "from" => 1, "to" => 1, "points" => nil },
      { "from" => 2, "to" => 2, "points" => nil },
      { "from" => 3, "to" => 3, "points" => nil },
      { "from" => 4, "to" => 7, "points" => nil }
    ]
  end

  def create
    @tournament = @league.tournaments.build(tournament_params)

    if @tournament.save
      redirect_to league_path(@league), notice: "Tournament created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def open_registration
    unless @tournament.draft?
      redirect_to league_path(@tournament.league), alert: t(".not_draft")
      return
    end

    @tournament.registration!
    redirect_to league_path(@tournament.league), notice: t(".success")
  end

  private

  def set_league
    @league = League.find(params[:league_id])
  end

  def set_tournament
    @tournament = Tournament.includes(pairs: [ { player1: :user }, { player2: :user } ]).find(params[:id])
  end

  def authorize_owner!
    redirect_to league_path(@league), alert: "Not authorized." unless @league.owner == current_user
  end

  def authorize_tournament_owner!
    redirect_to league_path(@tournament.league), alert: "Not authorized." unless @tournament.league.owner == current_user
  end

  def tournament_params
    params.require(:tournament).permit(
      :name, :start_date, :end_date, :max_participants, :location, :type, :description,
      placement_points: [ :from, :to, :points ]
    )
  end
end
