class DashboardController < ApplicationController
  def index
    @my_league_users        = LeagueUser.where(user: current_user).includes(:league)
    league_user_ids         = @my_league_users.select(:id)
    participated_league_ids = @my_league_users.select(:league_id)

    my_pairs      = Pair.where(player1_id: league_user_ids).or(Pair.where(player2_id: league_user_ids))
    my_pair_ids   = my_pairs.select(:id)
    my_pair_t_ids = my_pairs.select(:tournament_id)

    @my_leagues = League.where(owner: current_user)
                        .or(League.where(id: participated_league_ids))
                        .distinct

    # ── Hero stats ─────────────────────────────────────────────────────────
    @total_league_points = @my_league_users.sum(:score)
    completed            = Match.completed
                                .where("pair1_id IN (?) OR pair2_id IN (?)", my_pair_ids, my_pair_ids)
    @total_matches       = completed.count
    @wins                = completed.where(winner_id: my_pair_ids).count
    @win_rate            = @total_matches > 0 ? (@wins * 100.0 / @total_matches).round : 0
    @best_placement      = Pair.where(id: my_pair_ids).where.not(placement: nil).minimum(:placement)

    # ── Live tournaments (active status, user is registered) ───────────────
    @active_tournaments = Tournament.where(id: my_pair_t_ids)
                                    .where(status: "active")
                                    .order(start_date: :asc)
                                    .includes(:league)

    # ── Upcoming: registration-open and user is already registered ─────────
    @upcoming = Tournament.where(id: my_pair_t_ids)
                          .where(status: "registration")
                          .order(start_date: :asc)
                          .limit(5)
                          .includes(:league)

    # ── Open for registration in user's leagues (not yet registered) ───────
    @open_for_registration = Tournament
                               .where(league_id: @my_leagues.select(:id))
                               .where(status: "registration")
                               .where.not(id: my_pair_t_ids)
                               .order(start_date: :asc)
                               .limit(5)
                               .includes(:league)

    # ── Recent match history ───────────────────────────────────────────────
    @recent_matches = Match.completed
                           .where("pair1_id IN (?) OR pair2_id IN (?)", my_pair_ids, my_pair_ids)
                           .includes(
                             pair1: { player1: :user, player2: :user },
                             pair2: { player1: :user, player2: :user },
                             tournament: :league
                           )
                           .order(updated_at: :desc)
                           .limit(8)

    # ── League rankings (single batch query) ──────────────────────────────
    if @my_leagues.any?
      all_members_by_league = LeagueUser.where(league_id: @my_leagues.select(:id))
                                        .order(score: :desc)
                                        .group_by(&:league_id)
      @league_rankings = @my_league_users.map do |lu|
        members = all_members_by_league[lu.league_id] || []
        rank    = members.index { |m| m.user_id == current_user.id }.to_i + 1
        { league: lu.league, score: lu.score, rank: rank, total: members.count }
      end
    else
      @league_rankings = []
    end

    # ── Notifications ──────────────────────────────────────────────────────
    @recent_notifications = current_user.notifications.recent.limit(5)

    # ── Discovery: leagues user is not part of ─────────────────────────────
    @recent_leagues = League.where.not(id: @my_leagues.select(:id))
                            .order(created_at: :desc)
                            .limit(4)
                            .includes(:owner)

    # Used in view to identify current user's pair in each match
    @my_league_user_ids = @my_league_users.pluck(:id)
  end
end
