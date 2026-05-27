class ClubsController < ApplicationController
  def index
    @clubs = Club.all.order(:name)
  end

  def show
    @club = Club.find(params[:id])
    @tournaments = @club.tournaments.order(start_date: :desc)
  end
end
