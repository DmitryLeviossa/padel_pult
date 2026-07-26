module Tournaments
  module Matches
    class AddMatchService
      attr_reader :errors, :match

      def initialize(tournament, round_number)
        @tournament = tournament
        @round_number = round_number.to_i
        @errors = []
      end

      def call
        unless @tournament.round_robin?
          @errors << "Добавление матча доступно только для турниров по круговой системе."
          return false
        end

        if @round_number < 1
          @errors << "Некорректный номер раунда."
          return false
        end

        bracket = @tournament.brackets.bracket.first
        unless bracket
          @errors << "Не найдена сетка турнира."
          return false
        end

        position = bracket.matches.where(round_number: @round_number).maximum(:position).to_i + 1
        @match = bracket.matches.new(tournament: @tournament, round_number: @round_number, position: position, status: :pending)

        if @match.save
          true
        else
          @errors = @match.errors.full_messages
          false
        end
      end
    end
  end
end
