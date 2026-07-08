class TournamentsController < ApplicationController
  before_action :set_league, only: [ :new, :create ]
  before_action :set_tournament, only: [ :show, :edit, :update, :destroy, :open_registration, :activate, :cancel, :fill_results, :complete, :edit_placements, :update_placements, :online, :auto_assign_pairs, :seed_bracket, :copy ]
  before_action :authorize_owner!, only: [ :new, :create ]
  before_action :authorize_tournament_owner!, only: [ :edit, :update, :destroy, :open_registration, :activate, :cancel, :fill_results, :complete, :edit_placements, :update_placements, :auto_assign_pairs, :seed_bracket, :copy ]
  skip_before_action :authenticate_user!, only: [ :online ]

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
                          .includes(:bracket,
                                    :match_sets,
                                    pair1: [ { player1: :user }, { player2: :user } ],
                                    pair2: [ { player1: :user }, { player2: :user } ])

    if @tournament.americano?
      prepare_americano_data
      return
    end

    if @tournament.olympic?
      bracket_matches = @matches.select { |m| m.bracket? && m.group_number == 0 }
      grouped = bracket_matches.group_by(&:round_number).sort_by { |r, _| r }.map { |_, m| m }
      final_round = grouped.last || []
      @third_place_match = final_round.find { |m| m.position == 2 }
      @bracket_rounds = grouped[0..-2] + [ final_round.reject { |m| m.position == 2 } ]

      if @tournament.loser_bracket?
        @loser_bracket_rounds, @loser_third_place_match = extract_bracket_rounds(@matches.select(&:loser_bracket?))
      end
    elsif @tournament.mixed?
      prepare_mixed_data
    end

    manual_brackets = @tournament.brackets.where(bracket_type: :bracket).where("group_number > 0").order(:group_number)
    @custom_bracket_data = manual_brackets.map do |bracket|
      bracket_matches = @matches.select { |m| m.bracket_id == bracket.id }
      rounds, third_place = extract_bracket_rounds(bracket_matches)
      { bracket: bracket, rounds: rounds, third_place: third_place }
    end

    min_group_number = @tournament.groups_count.to_i + 1
    manual_groups = @tournament.brackets.where(bracket_type: :group_stage).where("group_number >= ?", min_group_number).order(:group_number)
    @custom_group_data = manual_groups.map do |bracket|
      group_matches = @matches.select { |m| m.bracket_id == bracket.id }
      { bracket: bracket, group_data: build_custom_group_data(group_matches) }
    end

    default_sort = @tournament.completed? ? "placement" : "score"
    default_dir  = @tournament.completed? ? "asc" : "desc"
    @sort = params[:sort].presence_in(%w[score player1 player2 player1_score player2_score created_at placement]) || default_sort
    @direction = params[:direction].presence_in(%w[asc desc]) || default_dir

    sorted = @tournament.pairs.sort_by do |pair|
      case @sort
      when "player1"       then [ pair.player1.full_name, pair.created_at ]
      when "player2"       then [ pair.player2.full_name, pair.created_at ]
      when "player1_score" then [ pair.player1_score, pair.created_at ]
      when "player2_score" then [ pair.player2_score, pair.created_at ]
      when "created_at"    then [ pair.created_at ]
      when "placement"     then [ pair.placement || Float::INFINITY, pair.created_at ]
      else                      [ pair.score, pair.created_at ]
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

      if @tournament.league.owner == current_user
        occupied_ids = @tournament.pairs.flat_map { |p| [ p.player1_id, p.player2_id ] }
        @owner_available_players = @tournament.league.league_users.includes(:user).where.not(id: occupied_ids)
        @all_league_users = @tournament.league.league_users.includes(:user).to_a
      end
    end

    if @tournament.active? && @tournament.league.owner == current_user
      @all_league_users = @tournament.league.league_users.includes(:user).to_a
    end
  end

  def online
    @tournament = Tournament
      .includes(:league, :club, :brackets,
                league: { logo_attachment: :blob },
                club: { logo_attachment: :blob },
                pairs: [ { player1: :user }, { player2: :user } ])
      .find(@tournament.id)
    @match_data = Tournaments::MatchData.new(@tournament)
    render layout: "online"
  end

  def new
    if @league.tournaments_quota&.zero?
      redirect_to league_path(@league), alert: "Квота на создание турниров исчерпана. Вы не можете создать больше турниров в этой лиге."
      return
    end

    @tournament = @league.tournaments.build
    @tournament.placement_points = [
      { "from" => 1, "to" => 1, "points" => nil },
      { "from" => 2, "to" => 2, "points" => nil },
      { "from" => 3, "to" => 3, "points" => nil },
      { "from" => 4, "to" => 7, "points" => nil }
    ]
  end

  def copy
    source = @tournament
    @league = source.league
    @tournament = @league.tournaments.build(
      source.attributes.except("id", "league_id", "status", "start_date", "end_date", "created_at", "updated_at")
    )
    render :new
  end

  def create
    @tournament = @league.tournaments.build(tournament_params)

    if @tournament.save
      redirect_to tournament_path(@tournament), notice: "Турнир успешно создан."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    unless @tournament.draft? || @tournament.league.owner == current_user
      redirect_to tournament_path(@tournament), alert: "Удалить можно только черновик."
      return
    end

    @tournament.destroy
    redirect_to league_path(@tournament.league, anchor: "tournaments"), notice: "Турнир удалён."
  end

  def edit
    unless @tournament.draft? || @tournament.registration?
      redirect_to tournament_path(@tournament), alert: "Редактировать можно только черновик или турнир на регистрации."
    end
  end

  def update
    unless @tournament.draft? || @tournament.registration?
      redirect_to tournament_path(@tournament), alert: "Редактировать можно только черновик или турнир на регистрации."
      return
    end

    if @tournament.update(tournament_params)
      redirect_to tournament_path(@tournament), notice: "Турнир успешно обновлён."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def open_registration
    unless @tournament.draft?
      redirect_to tournament_path(@tournament), alert: "Регистрацию можно открыть только для турнира в статусе черновика."
      return
    end

    @tournament.registration!
    notify_league_users_about_registration
    redirect_to tournament_path(@tournament), notice: "Регистрация на турнир открыта."
  end

  def activate
    unless @tournament.registration?
      redirect_to tournament_path(@tournament), alert: "Активировать можно только турнир с открытой регистрацией."
      return
    end

    if Tournaments::ActivateService.new(@tournament).call
      redirect_to tournament_path(@tournament), notice: "Турнир активирован."
    else
      redirect_to tournament_path(@tournament), alert: "Не удалось активировать турнир. Попробуйте ещё раз."
    end
  end

  def cancel
    unless @tournament.registration?
      redirect_to tournament_path(@tournament), alert: "Отменить можно только турнир с открытой регистрацией."
      return
    end

    @tournament.cancelled!
    notify_registered_players_about_cancellation
    redirect_to tournament_path(@tournament), notice: "Турнир отменён. Участники уведомлены."
  end

  def fill_results
    redirect_to(tournament_path(@tournament), alert: "Заполнить результаты можно только для активного турнира.") and return unless @tournament.active?

    if @tournament.americano?
      @americano_standings = @tournament.tournament_participants
                                        .includes(league_user: :user)
                                        .order(total_score: :desc, created_at: :asc)
      return
    end

    @suggested_placements = compute_suggested_placements
    @pairs = @tournament.pairs
                        .includes({ player1: :user }, { player2: :user })
                        .sort_by { |p| @suggested_placements.fetch(p.id, Float::INFINITY) }
  end

  def auto_assign_pairs
    if Tournaments::Matches::AutoAssignPairsService.new(@tournament).call
      redirect_to tournament_path(@tournament), notice: "Пары автоматически расставлены."
    else
      redirect_to tournament_path(@tournament), alert: "Не удалось расставить пары. Возможно, некоторые матчи уже сыграны."
    end
  end

  def seed_bracket
    Tournaments::Matches::StartBracketService.new(@tournament).call
    redirect_to tournament_path(@tournament), notice: "Сетка заполнена."
  rescue ActiveRecord::RecordNotFound
    redirect_to tournament_path(@tournament), alert: "Не удалось заполнить сетку: неверная структура турнира."
  end

  def complete
    unless @tournament.active?
      redirect_to tournament_path(@tournament), alert: "Завершить можно только активный турнир."
      return
    end

    if Tournaments::CompleteService.new(@tournament, params[:placements] || {}).call
      redirect_to tournament_path(@tournament), notice: "Турнир завершён, очки начислены."
    else
      redirect_to tournament_path(@tournament), alert: "Не удалось завершить турнир. Попробуйте ещё раз."
    end
  end

  def edit_placements
    unless @tournament.completed?
      redirect_to tournament_path(@tournament), alert: "Редактировать места можно только у завершённого турнира."
      return
    end

    if @tournament.americano?
      @participants = @tournament.tournament_participants
                                 .includes(league_user: :user)
                                 .order(:placement)
    else
      @pairs = @tournament.pairs
                          .includes({ player1: :user }, { player2: :user })
                          .sort_by { |p| p.placement || Float::INFINITY }
    end
  end

  def update_placements
    unless @tournament.completed?
      redirect_to tournament_path(@tournament), alert: "Обновить места можно только у завершённого турнира."
      return
    end

    if Tournaments::UpdatePlacementsService.new(@tournament, params[:placements] || {}).call
      redirect_to tournament_path(@tournament), notice: "Места обновлены, очки пересчитаны."
    else
      redirect_to tournament_path(@tournament), alert: "Не удалось обновить места. Попробуйте ещё раз."
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
        message: "Открыта регистрация на турнир «#{@tournament.name}» в лиге «#{@tournament.league.name}»",
        url: tournament_path(@tournament)
      )
    end
  end

  def notify_registered_players_about_cancellation
    registered_users = if @tournament.americano?
      @tournament.tournament_participants.includes(league_user: :user).map { |p| p.league_user.user }
    else
      @tournament.pairs.includes(player1: :user, player2: :user).flat_map do |pair|
        [ pair.player1.user, pair.player2.user ]
      end
    end.uniq

    registered_users.each do |user|
      Notification.create!(
        user: user,
        notification_type: :tournament_cancelled,
        message: "Турнир «#{@tournament.name}» был отменён",
        url: tournament_path(@tournament)
      )
    end
  end

  def authorize_owner!
    redirect_to league_path(@league), alert: "Нет доступа." unless @league.owner == current_user
  end

  def authorize_tournament_owner!
    redirect_to league_path(@tournament.league), alert: "Нет доступа." unless @tournament.league.owner == current_user
  end

  def prepare_americano_data
    is_owner = @tournament.league.owner == current_user
    @current_league_user = @tournament.league.league_users.find_by(user: current_user)

    if @tournament.registration?
      registered_ids = @tournament.tournament_participants.pluck(:league_user_id).to_set
      already_registered = @current_league_user && registered_ids.include?(@current_league_user.id)

      unless already_registered || @current_league_user.nil?
        @can_register = true
      end

      if is_owner
        @owner_available_players = @tournament.league.league_users
                                              .includes(:user)
                                              .where.not(id: registered_ids.to_a)
      end
    end

    sort_field = params[:sort].presence_in(%w[name total_score placement created_at]) ||
                 (@tournament.completed? ? "placement" : "total_score")
    sort_dir = params[:direction].presence_in(%w[asc desc]) ||
               (@tournament.completed? ? "asc" : "desc")

    participants = @tournament.tournament_participants.includes(league_user: :user).to_a
    sorted = participants.sort_by do |p|
      case sort_field
      when "name"       then [ p.league_user.full_name, p.created_at ]
      when "placement"  then [ p.placement || Float::INFINITY, p.created_at ]
      when "created_at" then [ p.created_at ]
      else                   [ p.total_score, p.created_at ]
      end
    end
    @americano_participants = sort_dir == "desc" ? sorted.reverse : sorted

    @americano_rounds = @matches.group_by(&:round_number).sort_by { |r, _| r }.map { |r, ms| { round: r, matches: ms } }

    render :show_americano
  end

  def prepare_mixed_data
    return unless @tournament.groups_count.present?

    group_matches = @matches.select(&:group_stage?)

    @group_data = (1..@tournament.groups_count).map do |g|
      g_matches = group_matches.select { |m| m.group_number == g }
      pair_ids  = g_matches.flat_map { |m| [ m.pair1_id, m.pair2_id ] }.compact.uniq

      # Stable ordering: seed (highest score) first, then by id for determinism
      pairs_ordered = @tournament.pairs
                                 .select { |p| pair_ids.include?(p.id) }
                                 .sort_by { |p| [ p.seeded? ? 0 : 1, -p.score, p.id ] }

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
        games_won  = g_matches.sum { |m|
          next 0 unless m.completed?
          m.pair1_id == pair.id ? m.match_sets.sum(&:pair1_score) : (m.pair2_id == pair.id ? m.match_sets.sum(&:pair2_score) : 0)
        }
        games_lost = g_matches.sum { |m|
          next 0 unless m.completed?
          m.pair1_id == pair.id ? m.match_sets.sum(&:pair2_score) : (m.pair2_id == pair.id ? m.match_sets.sum(&:pair1_score) : 0)
        }
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

    @bracket_rounds, @third_place_match = extract_bracket_rounds(@matches.select { |m| m.bracket? && m.group_number == 0 })

    if @tournament.loser_bracket?
      @loser_bracket_rounds, @loser_third_place_match = extract_bracket_rounds(@matches.select(&:loser_bracket?))
    end

    real_group_matches = @tournament.matches.group_stage.where.not(pair1_id: nil, pair2_id: nil)
    all_groups_done = real_group_matches.exists? && !real_group_matches.pending.exists?
    bracket_r1 = @bracket_rounds.first || []
    @bracket_unseeded = all_groups_done && bracket_r1.any? && bracket_r1.all? { |m| m.pair1_id.nil? }
    @bracket_slot_labels = @tournament.bracket_slot_labels
  end

  def extract_bracket_rounds(matches)
    return [ [], nil ] if matches.empty?

    grouped = matches.group_by(&:round_number).sort_by { |r, _| r }.map { |_, ms| ms }
    third_place = grouped.last&.find { |m| m.position == 2 }
    rounds = grouped[0..-2] + [ grouped.last.reject { |m| m.position == 2 } ]
    [ rounds, third_place ]
  end

  def build_custom_group_data(group_matches)
    pair_ids = group_matches.flat_map { |m| [ m.pair1_id, m.pair2_id ] }.compact.uniq
    pairs_ordered = @tournament.pairs
                               .select { |p| pair_ids.include?(p.id) }
                               .sort_by { |p| [ p.seeded? ? 0 : 1, -p.score, p.id ] }

    pair_index = {}
    pairs_ordered.each_with_index { |p, i| pair_index[p.id] = i + 1 }

    scores    = Hash.new { |h, k| h[k] = {} }
    match_for = Hash.new { |h, k| h[k] = {} }

    group_matches.each do |match|
      next unless match.pair1_id && match.pair2_id
      match_for[match.pair1_id][match.pair2_id] = match
      match_for[match.pair2_id][match.pair1_id] = match
      next unless match.completed?
      scores[match.pair1_id][match.pair2_id] = [ match.pair1_score, match.pair2_score ]
      scores[match.pair2_id][match.pair1_id] = [ match.pair2_score, match.pair1_score ]
    end

    stats_by_id = {}
    pairs_ordered.each do |pair|
      wins = group_matches.count { |m| m.completed? && m.winner_id == pair.id }
      games_won = group_matches.sum { |m|
        next 0 unless m.completed?
        m.pair1_id == pair.id ? m.match_sets.sum(&:pair1_score) : (m.pair2_id == pair.id ? m.match_sets.sum(&:pair2_score) : 0)
      }
      games_lost = group_matches.sum { |m|
        next 0 unless m.completed?
        m.pair1_id == pair.id ? m.match_sets.sum(&:pair2_score) : (m.pair2_id == pair.id ? m.match_sets.sum(&:pair1_score) : 0)
      }
      stats_by_id[pair.id] = { pair: pair, wins: wins, games_diff: games_won - games_lost }
    end

    sorted_stats = stats_by_id.values.sort_by { |s| [ -s[:wins], -s[:games_diff] ] }
    sorted_stats.each_with_index { |s, i| s[:place] = i + 1 }

    {
      pairs_ordered: pairs_ordered,
      pair_index:    pair_index,
      stats_by_id:   stats_by_id,
      scores:        scores,
      match_for:     match_for,
      all_matches:   group_matches
    }
  end

  def compute_suggested_placements
    matches = @tournament.matches.ordered.includes(:match_sets)
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
      wins_count  = Hash.new(0)
      pts_for     = Hash.new(0)
      pts_against = Hash.new(0)
      head_to_head = {}

      matches.where(status: :completed).each do |match|
        next unless match.winner_id.present? && match.pair1_id.present? && match.pair2_id.present?
        loser_id = match.pair1_id == match.winner_id ? match.pair2_id : match.pair1_id

        if match.match_sets.any?
          p1_pts = match.match_sets.sum(&:pair1_score)
          p2_pts = match.match_sets.sum(&:pair2_score)
        else
          p1_pts = match.pair1_score.to_i
          p2_pts = match.pair2_score.to_i
        end

        pts_for[match.pair1_id]     += p1_pts
        pts_against[match.pair1_id] += p2_pts
        pts_for[match.pair2_id]     += p2_pts
        pts_against[match.pair2_id] += p1_pts

        wins_count[match.winner_id] += 1
        head_to_head[[ match.winner_id, loser_id ]] = match.winner_id
        head_to_head[[ loser_id, match.winner_id ]] = match.winner_id
      end

      pair_stats = @tournament.pairs.map do |pair|
        net = pts_for[pair.id] - pts_against[pair.id]
        [ pair.id, wins_count[pair.id], net ]
      end

      sorted = pair_stats.sort do |(id_a, wins_a, net_a), (id_b, wins_b, net_b)|
        h2h = head_to_head[[ id_a, id_b ]]
        h2h_cmp = h2h == id_a ? -1 : (h2h == id_b ? 1 : 0)
        if @tournament.by_wins?
          wins_a != wins_b ? wins_b <=> wins_a : (net_a != net_b ? net_b <=> net_a : h2h_cmp)
        else
          net_a != net_b ? net_b <=> net_a : h2h_cmp
        end
      end

      sorted.each_with_index do |(pair_id, _, _), idx|
        placements[pair_id] = idx + 1
      end
    end

    placements
  end

  def tournament_params
    base = params.require(:tournament).permit(
      :name, :start_date, :end_date, :max_participants, :club_id, :type, :description,
      :groups_count, :pairs_to_bracket, :loser_bracket, :rounds_count, :ranking_method
    )

    raw_pp = params.dig(:tournament, :placement_points)
    if raw_pp.is_a?(ActionController::Parameters)
      base[:placement_points] = raw_pp.to_unsafe_h
                                      .sort_by { |k, _| k.to_i }
                                      .map { |_, v| v.slice("from", "to", "points") }
    elsif raw_pp.is_a?(Array)
      base[:placement_points] = raw_pp.map do |v|
        h = v.is_a?(ActionController::Parameters) ? v.to_unsafe_h : v.stringify_keys
        h.slice("from", "to", "points")
      end
    end

    base
  end
end
