class TournamentsController < ApplicationController
  before_action :set_league, only: [ :new, :create ]
  before_action :set_tournament, only: [ :show, :edit, :update, :destroy, :open_registration, :activate, :cancel, :fill_results, :complete ]
  before_action :authorize_owner!, only: [ :new, :create ]
  before_action :authorize_tournament_owner!, only: [ :edit, :update, :destroy, :open_registration, :activate, :cancel, :fill_results, :complete ]

  def index
    filter_params = params[:q]&.to_unsafe_h || {}
    filter_params[:status_in] = %w[registration active] if filter_params[:status_in].blank?
    @scope = params[:scope].presence_in(%w[all my_leagues]) || "my_leagues"
    base = Tournament.where.not(status: :draft)
    base = base.where(league_id: current_user.leagues.select(:id)) if @scope == "my_leagues"
    @q = base.ransack(filter_params)
    @tournaments = @q.result.includes(:pairs)
  end

  def show
    @matches = @tournament.matches.ordered
                          .includes(pair1: [ { player1: :user }, { player2: :user } ],
                                    pair2: [ { player1: :user }, { player2: :user } ])

    if @tournament.olympic?
      grouped = @matches.group_by(&:round_number).sort_by { |r, _| r }.map { |_, m| m }
      final_round = grouped.last || []
      @third_place_match = final_round.find { |m| m.position == 2 }
      @bracket_rounds = grouped[0..-2] + [ final_round.reject { |m| m.position == 2 } ]
    elsif @tournament.mixed?
      prepare_mixed_data
    end

    default_sort = @tournament.completed? ? "placement" : "score"
    default_dir  = @tournament.completed? ? "asc" : "desc"
    @sort = params[:sort].presence_in(%w[score player1 player2 player1_score player2_score created_at placement]) || default_sort
    @direction = params[:direction].presence_in(%w[asc desc]) || default_dir

    sorted = @tournament.pairs.sort_by do |pair|
      case @sort
      when "player1"       then pair.player1.full_name
      when "player2"       then pair.player2.full_name
      when "player1_score" then pair.player1_score
      when "player2_score" then pair.player2_score
      when "created_at"    then pair.created_at
      when "placement"     then pair.placement || Float::INFINITY
      else                      pair.score
      end
    end

    @pairs = @direction == "desc" ? sorted.reverse : sorted

    if @tournament.registration?
      @current_league_user = @tournament.league.league_users.find_by(user: current_user)
      if @current_league_user
        already_in = @tournament.pairs.any? { |p| p.player1_id == @current_league_user.id || p.player2_id == @current_league_user.id }
        unless already_in
          occupied_ids = @tournament.pairs.flat_map { |p| [ p.player1_id, p.player2_id ] }
          @available_partners = @tournament.league.league_users
                                           .includes(:user)
                                           .where.not(id: [ @current_league_user.id ] + occupied_ids)
        end
      end
    end
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
      redirect_to league_path(@league, anchor: "tournaments"), notice: "Tournament created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    unless @tournament.draft?
      redirect_to tournament_path(@tournament), alert: t(".not_draft")
      return
    end

    @tournament.destroy
    redirect_to league_path(@tournament.league, anchor: "tournaments"), notice: t(".success")
  end

  def edit
    redirect_to tournament_path(@tournament), alert: t(".not_draft") unless @tournament.draft?
  end

  def update
    unless @tournament.draft?
      redirect_to tournament_path(@tournament), alert: t(".not_draft")
      return
    end

    if @tournament.update(tournament_params)
      redirect_to tournament_path(@tournament), notice: t(".success")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def open_registration
    unless @tournament.draft?
      redirect_to league_path(@tournament.league, anchor: "tournaments"), alert: t(".not_draft")
      return
    end

    @tournament.registration!
    notify_league_users_about_registration
    redirect_to league_path(@tournament.league, anchor: "tournaments"), notice: t(".success")
  end

  def activate
    unless @tournament.registration?
      redirect_to tournament_path(@tournament), alert: t(".not_registration")
      return
    end

    if Tournaments::ActivateService.new(@tournament).call
      redirect_to tournament_path(@tournament), notice: t(".success")
    else
      redirect_to tournament_path(@tournament), alert: t(".activate_failed")
    end
  end

  def cancel
    unless @tournament.registration?
      redirect_to tournament_path(@tournament), alert: t(".not_registration")
      return
    end

    @tournament.cancelled!
    notify_registered_players_about_cancellation
    redirect_to tournament_path(@tournament), notice: t(".success")
  end

  def fill_results
    redirect_to tournament_path(@tournament), alert: t(".completed") if @tournament.completed?
    @suggested_placements = compute_suggested_placements
    @pairs = @tournament.pairs
                        .includes({ player1: :user }, { player2: :user })
                        .sort_by { |p| @suggested_placements.fetch(p.id, Float::INFINITY) }
  end

  def complete
    if @tournament.completed?
      redirect_to tournament_path(@tournament), alert: t(".completed")
      return
    end

    if Tournaments::CompleteService.new(@tournament, params[:placements] || {}).call
      redirect_to tournament_path(@tournament), notice: t(".success")
    else
      redirect_to fill_results_tournament_path(@tournament), alert: t(".failure")
    end
  end

  private

  def set_league
    @league = League.find(params[:league_id])
  end

  def set_tournament
    @tournament = Tournament.includes(pairs: [ { player1: :user }, { player2: :user } ]).find(params[:id])
  end

  def notify_league_users_about_registration
    @tournament.league.league_users.includes(:user).each do |league_user|
      Notification.create!(
        user: league_user.user,
        notification_type: :tournament_registration_open,
        message: t("tournaments.notifications.registration_open", tournament: @tournament.name),
        url: tournament_path(@tournament)
      )
    end
  end

  def notify_registered_players_about_cancellation
    registered_users = @tournament.pairs.includes(player1: :user, player2: :user).flat_map do |pair|
      [ pair.player1.user, pair.player2.user ]
    end.uniq

    registered_users.each do |user|
      Notification.create!(
        user: user,
        notification_type: :tournament_cancelled,
        message: t("tournaments.notifications.cancelled", tournament: @tournament.name),
        url: tournament_path(@tournament)
      )
    end
  end

  def authorize_owner!
    redirect_to league_path(@league), alert: "Not authorized." unless @league.owner == current_user
  end

  def authorize_tournament_owner!
    redirect_to league_path(@tournament.league), alert: "Not authorized." unless @tournament.league.owner == current_user
  end

  def prepare_mixed_data
    group_matches = @matches.select(&:group_stage?)

    @group_data = (1..@tournament.groups_count).map do |g|
      g_matches = group_matches.select { |m| m.group_number == g }
      pair_ids  = g_matches.flat_map { |m| [ m.pair1_id, m.pair2_id ] }.compact.uniq

      # Stable ordering: seed (highest score) first, then by id for determinism
      pairs_ordered = @tournament.pairs
                                 .select { |p| pair_ids.include?(p.id) }
                                 .sort_by { |p| [ -p.score, p.id ] }

      # pair_index[pair_id] => 1-based position in stable order (for column headers)
      pair_index = {}
      pairs_ordered.each_with_index { |p, i| pair_index[p.id] = i + 1 }

      # Score matrix and match lookup
      scores    = Hash.new { |h, k| h[k] = {} }
      match_for = Hash.new { |h, k| h[k] = {} }

      g_matches.each do |match|
        next unless match.pair1_id && match.pair2_id
        match_for[match.pair1_id][match.pair2_id] = match
        match_for[match.pair2_id][match.pair1_id] = match
        next unless match.completed?
        scores[match.pair1_id][match.pair2_id] = [ match.pair1_score, match.pair2_score ]
        scores[match.pair2_id][match.pair1_id] = [ match.pair2_score, match.pair1_score ]
      end

      # Standings: wins first, then game differential
      stats_by_id = {}
      pairs_ordered.each do |pair|
        wins       = g_matches.count { |m| m.completed? && m.winner_id == pair.id }
        games_won  = g_matches.sum { |m| m.pair1_id == pair.id ? m.pair1_score.to_i : (m.pair2_id == pair.id ? m.pair2_score.to_i : 0) }
        games_lost = g_matches.sum { |m| m.pair1_id == pair.id ? m.pair2_score.to_i : (m.pair2_id == pair.id ? m.pair1_score.to_i : 0) }
        stats_by_id[pair.id] = { pair: pair, wins: wins, games_diff: games_won - games_lost }
      end

      sorted_stats = stats_by_id.values.sort_by { |s| [ -s[:wins], -s[:games_diff] ] }
      sorted_stats.each_with_index { |s, i| s[:place] = i + 1 }

      {
        group_number:  g,
        pairs_ordered: pairs_ordered,
        pair_index:    pair_index,
        stats_by_id:   stats_by_id,
        scores:        scores,
        match_for:     match_for
      }
    end

    @bracket_rounds, @third_place_match = extract_bracket_rounds(@matches.select(&:bracket?))

    if @tournament.loser_bracket?
      @loser_bracket_rounds, @loser_third_place_match = extract_bracket_rounds(@matches.select(&:loser_bracket?))
    end
  end

  def extract_bracket_rounds(matches)
    return [ [], nil ] if matches.empty?

    grouped = matches.group_by(&:round_number).sort_by { |r, _| r }.map { |_, ms| ms }
    third_place = grouped.last&.find { |m| m.position == 2 }
    rounds = grouped[0..-2] + [ grouped.last.reject { |m| m.position == 2 } ]
    [ rounds, third_place ]
  end

  def compute_suggested_placements
    matches = @tournament.matches.ordered
    return {} unless matches.any?

    placements = {}

    if @tournament.olympic?
      grouped = matches.group_by(&:round_number).sort_by { |r, _| r }
      total_rounds = grouped.length

      grouped.each_with_index do |(_, round_matches), idx|
        rounds_from_end = total_rounds - 1 - idx

        round_matches.each do |match|
          next unless match.winner_id.present?
          loser_id = [ match.pair1_id, match.pair2_id ].find { |id| id.present? && id != match.winner_id }
          next unless loser_id

          if rounds_from_end == 0
            if match.position == 1
              placements[match.winner_id] = 1
              placements[loser_id] = 2
            elsif match.position == 2
              placements[match.winner_id] = 3
              placements[loser_id] = 4
            end
          elsif rounds_from_end >= 2
            placements[loser_id] = 2 ** rounds_from_end + 1
          end
        end
      end
    elsif @tournament.round_robin?
      wins_score  = Hash.new(0)
      losses_score = Hash.new(0)

      matches.where(status: :completed).each do |match|
        next unless match.winner_id.present?
        loser_id = match.pair1_id == match.winner_id ? match.pair2_id : match.pair1_id

        winner_score = match.pair1_id == match.winner_id ? match.pair1_score.to_i : match.pair2_score.to_i
        loser_score  = match.pair1_id == match.winner_id ? match.pair2_score.to_i : match.pair1_score.to_i

        wins_score[match.winner_id] += winner_score
        losses_score[loser_id] += loser_score
      end

      sorted = @tournament.pairs
                          .map { |pair| [ pair.id, wins_score[pair.id] - losses_score[pair.id] ] }
                          .sort_by { |_, net| -net }

      sorted.each_with_index do |(pair_id, _), idx|
        placements[pair_id] = idx + 1
      end
    end

    placements
  end

  def tournament_params
    base = params.require(:tournament).permit(
      :name, :start_date, :end_date, :max_participants, :location, :type, :description,
      :groups_count, :pairs_to_bracket, :loser_bracket
    )

    raw_pp = params.dig(:tournament, :placement_points)
    if raw_pp.is_a?(ActionController::Parameters)
      base[:placement_points] = raw_pp.to_unsafe_h
                                      .sort_by { |k, _| k.to_i }
                                      .map { |_, v| v.slice("from", "to", "points") }
    end

    base
  end
end
