module Tournaments
  class MatchData
    attr_reader :tournament, :matches,
                :bracket_rounds, :third_place_match,
                :group_data, :loser_bracket_rounds, :loser_third_place_match,
                :custom_bracket_data, :custom_group_data, :result_card_matches,
                :bracket_slot_labels

    def initialize(tournament)
      @tournament = tournament
      @matches = tournament.matches.ordered
                           .includes(:bracket,
                                     :match_sets,
                                     pair1: [ { player1: :user }, { player2: :user } ],
                                     pair2: [ { player1: :user }, { player2: :user } ])
      prepare
    end

    def to_locals
      {
        tournament: @tournament,
        matches: @matches,
        bracket_rounds: @bracket_rounds,
        third_place_match: @third_place_match,
        group_data: @group_data,
        loser_bracket_rounds: @loser_bracket_rounds,
        loser_third_place_match: @loser_third_place_match,
        custom_bracket_data: @custom_bracket_data,
        custom_group_data: @custom_group_data,
        result_card_matches: @result_card_matches,
        bracket_slot_labels: @bracket_slot_labels
      }
    end

    private

    def prepare
      @result_card_matches = @tournament.matches
                                        .completed
                                        .joins(:result_card_image_attachment)
                                        .with_attached_result_card_image
                                        .order(updated_at: :desc)

      if @tournament.olympic?
        @bracket_rounds, @third_place_match = extract_bracket_rounds(@matches.select { |m| m.bracket? && m.group_number == 0 })

        if @tournament.loser_bracket?
          @loser_bracket_rounds, @loser_third_place_match = extract_bracket_rounds(@matches.select(&:loser_bracket?))
        end
      elsif @tournament.mixed?
        prepare_mixed
      end

      prepare_custom_brackets
      prepare_custom_groups
    end

    def prepare_mixed
      return unless @tournament.groups_count.present?

      group_matches = @matches.select(&:group_stage?)

      @group_data = (1..@tournament.groups_count).map do |g|
        g_matches = group_matches.select { |m| m.group_number == g }
        pair_ids  = g_matches.flat_map { |m| [ m.pair1_id, m.pair2_id ] }.compact.uniq

        pairs_ordered = @tournament.pairs
                                   .select { |p| pair_ids.include?(p.id) }
                                   .sort_by { |p| [ p.seeded? ? 0 : 1, -p.score, p.id ] }

        pair_index = {}
        pairs_ordered.each_with_index { |p, i| pair_index[p.id] = i + 1 }

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
      @bracket_slot_labels = @tournament.bracket_slot_labels

      if @tournament.loser_bracket?
        @loser_bracket_rounds, @loser_third_place_match = extract_bracket_rounds(@matches.select(&:loser_bracket?))
      end
    end

    def prepare_custom_brackets
      manual_brackets = @tournament.brackets
                                   .select { |b| b.bracket? && b.group_number > 0 }
                                   .sort_by(&:group_number)
      @custom_bracket_data = manual_brackets.map do |bracket|
        bracket_matches = @matches.select { |m| m.bracket_id == bracket.id }
        rounds, third_place = extract_bracket_rounds(bracket_matches)
        { bracket: bracket, rounds: rounds, third_place: third_place }
      end
    end

    def prepare_custom_groups
      min_group_number = @tournament.groups_count.to_i + 1
      manual_groups = @tournament.brackets
                                 .select { |b| b.group_stage? && b.group_number >= min_group_number }
                                 .sort_by(&:group_number)
      @custom_group_data = manual_groups.map do |bracket|
        group_matches = @matches.select { |m| m.bracket_id == bracket.id }
        { bracket: bracket, group_data: build_group_data(group_matches) }
      end
    end

    def build_group_data(group_matches)
      pair_ids = group_matches.flat_map { |m| [ m.pair1_id, m.pair2_id ] }.compact.uniq
      pairs_ordered = @tournament.pairs
                                 .select { |p| pair_ids.include?(p.id) }
                                 .sort_by { |p| [ p.seeded? ? 0 : 1, -p.score, p.id ] }

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

      { pairs_ordered: pairs_ordered, stats_by_id: stats_by_id, scores: scores, match_for: match_for }
    end

    def extract_bracket_rounds(bracket_matches)
      return [ [], nil ] if bracket_matches.empty?

      grouped = bracket_matches.group_by(&:round_number).sort_by { |r, _| r }.map { |_, ms| ms }
      third_place = grouped.last&.find { |m| m.position == 2 }
      rounds = grouped[0..-2] + [ grouped.last.reject { |m| m.position == 2 } ]
      [ rounds, third_place ]
    end
  end
end
