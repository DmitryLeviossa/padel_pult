module Brackets
  class CreateService
    def initialize(tournament, params)
      @tournament = tournament
      @params = params
    end

    def call
      pairs_count = @params[:pairs_count].to_i
      next_group_number = @tournament.brackets.where(bracket_type: :bracket).maximum(:group_number).to_i + 1

      bracket = @tournament.brackets.build(
        bracket_type: :bracket,
        group_number: next_group_number,
        name: @params[:name],
        pairs_count: pairs_count
      )

      return bracket unless bracket.valid?

      ActiveRecord::Base.transaction do
        bracket.save!
        generate_matches(bracket, pairs_count)
      end

      bracket
    rescue ActiveRecord::RecordInvalid
      bracket
    end

    private

    def generate_matches(bracket, pairs_count)
      n = next_power_of_two(pairs_count)
      total_rounds = Math.log2(n).to_i

      (n / 2).times do |i|
        bracket.matches.create!(tournament: @tournament, round_number: 1, position: i + 1, status: :pending)
      end

      (2..total_rounds).each do |round|
        (n / (2**round)).times do |i|
          bracket.matches.create!(tournament: @tournament, round_number: round, position: i + 1, status: :pending)
        end
      end

      return unless total_rounds > 1

      bracket.matches.create!(tournament: @tournament, round_number: total_rounds, position: 2, status: :pending)
    end

    def next_power_of_two(n)
      return 2 if n <= 2
      2**Math.log2(n).ceil
    end
  end
end
