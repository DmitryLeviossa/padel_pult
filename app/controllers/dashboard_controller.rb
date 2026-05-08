class DashboardController < ApplicationController
  def index
    @my_leagues = League.where(owner: current_user)
    @my_tournaments = Tournament.joins(:league).where(leagues: { owner_id: current_user.id })
    @recent_leagues = League.order(created_at: :desc).limit(5)
  end
end
