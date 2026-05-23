module Tournaments
  class MatchData
    attr_reader :tournament, :matches,
                :bracket_rounds, :third_place_match,
                :group_data, :loser_bracket_rounds, :loser_third_place_match

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
        loser_third_place_match: @loser_third_place_match
      }
    end

    private

    def prepare
      if @tournament.olympic?
        @bracket_rounds, @third_place_match = extract_bracket_rounds(@matches.reject(&:loser_bracket?))

        if @tournament.loser_bracket?
          @loser_bracket_rounds, @loser_third_place_match = extract_bracket_rounds(@matches.select(&:loser_bracket?))
        end
      elsif @tournament.mixed?
        prepare_mixed
      end
    end

    def prepare_mixed
      return unless @tournament.groups_count.present?

      group_matches = @matches.select(&:group_stage?)

      @group_data = (1..@tournament.groups_count).map do |g|
        g_matches = group_matches.select { |m| m.group_number == g }
        pair_ids  = g_matches.flat_map { |m| [ m.pair1_id, m.pair2_id ] }.compact.uniq

        pairs_ordered = @tournament.pairs
                                   .select { |p| pair_ids.include?(p.id) }
                                   .sort_by { |p| [ -p.score, p.id ] }

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

    def extract_bracket_rounds(bracket_matches)
      return [ [], nil ] if bracket_matches.empty?

      grouped = bracket_matches.group_by(&:round_number).sort_by { |r, _| r }.map { |_, ms| ms }
      third_place = grouped.last&.find { |m| m.position == 2 }
      rounds = grouped[0..-2] + [ grouped.last.reject { |m| m.position == 2 } ]
      [ rounds, third_place ]
    end
  end
end
