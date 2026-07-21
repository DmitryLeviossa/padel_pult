module Tournaments
  module Matches
    class ManualAssignPairsService
      attr_reader :errors

      # assignments: { pair_id => group_number }
      def initialize(tournament, assignments)
        @tournament = tournament
        @assignments = assignments.to_h { |pair_id, group_number| [ pair_id.to_i, group_number.to_i ] }
        @errors = []
      end

      def call
        if @tournament.matches.completed.any?
          @errors << "Некоторые матчи уже сыграны."
          return false
        end

        return false unless valid_assignments?

        ActiveRecord::Base.transaction do
          @tournament.matches.update_all(pair1_id: nil, pair2_id: nil, winner_id: nil, status: "pending")
          grouped_pairs.each { |group_number, pairs| assign_group_matches(pairs, group_number) }
        end

        true
      rescue => e
        Rails.logger.error("ManualAssignPairsService failed: #{e.message}")
        @errors << "Внутренняя ошибка. Попробуйте ещё раз."
        false
      end

      private

      def valid_assignments?
        pairs = @tournament.pairs.to_a
        pair_ids = pairs.map(&:id)

        if @assignments.keys.sort != pair_ids.sort
          @errors << "Нужно распределить все пары по группам."
          return false
        end

        count = @tournament.groups_count
        if @assignments.values.any? { |g| g < 1 || g > count }
          @errors << "Некорректный номер группы."
          return false
        end

        actual_sizes = Array.new(count, 0)
        @assignments.each_value { |g| actual_sizes[g - 1] += 1 }

        if actual_sizes != target_sizes(pairs.length, count)
          @errors << "Количество пар в каждой группе должно совпадать с текущим распределением."
          return false
        end

        true
      end

      # Preserves the current per-group headcount (owner may only move pairs
      # between groups, not change how many pairs each group holds). Falls
      # back to a near-equal split when groups have no pairs assigned yet.
      def target_sizes(total, count)
        current = current_group_sizes(count)
        return current if current.sum == total

        base = total / count
        remainder = total % count
        Array.new(count) { |i| base + (i < remainder ? 1 : 0) }
      end

      def current_group_sizes(count)
        group_matches = @tournament.matches.group_stage.to_a
        Array.new(count) do |i|
          group_number = i + 1
          group_matches.select { |m| m.group_number == group_number }
                       .flat_map { |m| [ m.pair1_id, m.pair2_id ] }
                       .compact.uniq.length
        end
      end

      def grouped_pairs
        pairs_by_id = @tournament.pairs.index_by(&:id)
        grouped = Hash.new { |h, k| h[k] = [] }
        @assignments.each { |pair_id, group_number| grouped[group_number] << pairs_by_id[pair_id] }
        grouped
      end

      def assign_group_matches(pairs, group_number)
        bracket = @tournament.brackets.group_stage.find_by!(group_number: group_number)
        GroupRoundRobinScheduler.call(bracket, pairs)
      end
    end
  end
end
