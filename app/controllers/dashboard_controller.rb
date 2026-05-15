class DashboardController < ApplicationController
  def index
    league_user_ids = LeagueUser.where(user: current_user).select(:id)
    participated_league_ids = LeagueUser.where(user: current_user).select(:league_id)
    pair_tournament_ids = Pair.where(player1_id: league_user_ids)
                              .or(Pair.where(player2_id: league_user_ids))
                              .select(:tournament_id)
    owned_league_ids = League.where(owner: current_user).select(:id)

    @my_leagues = League.where(owner: current_user)
                        .or(League.where(id: participated_league_ids))
                        .distinct

    @my_tournaments = Tournament.where(league_id: owned_league_ids)
                                .or(Tournament.where(id: pair_tournament_ids))
                                .includes(:pairs)
                                .distinct

    @recent_leagues = League.order(created_at: :desc).limit(5)
  end
end
