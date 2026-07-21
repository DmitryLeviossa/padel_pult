module Tournaments
  module Matches
    module GroupRoundRobinScheduler
      module_function

      def call(bracket, pairs)
        list = pairs.dup
        list << nil if list.length.odd?
        n = list.length

        (n - 1).times do |round_idx|
          (n / 2).times do |i|
            pair1 = list[i]
            pair2 = list[n - 1 - i]
            next if pair1.nil? || pair2.nil?

            match = bracket.matches.find_or_create_by!(round_number: round_idx + 1, position: i + 1) do |m|
              m.tournament = bracket.tournament
              m.status = :pending
            end
            match.update!(pair1: pair1, pair2: pair2)
          end

          list = [ list[0] ] + [ list[-1] ] + list[1...-1]
        end
      end
    end
  end
end
