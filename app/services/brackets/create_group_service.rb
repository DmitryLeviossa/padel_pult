module Brackets
  class CreateGroupService
    def initialize(tournament, params)
      @tournament = tournament
      @params = params
    end

    def call
      pair_ids = Array(@params[:pair_ids]).map(&:to_i).select(&:positive?)
      pairs = @tournament.pairs.where(id: pair_ids).to_a

      next_group_number = @tournament.brackets.where(bracket_type: :group_stage).maximum(:group_number).to_i + 1

      bracket = @tournament.brackets.build(
        bracket_type: :group_stage,
        group_number: next_group_number,
        name: @params[:name],
        pairs_count: pairs.size
      )

      if pairs.size < 2
        bracket.errors.add(:base, "Выберите не менее 2 пар")
        return bracket
      end

      return bracket unless bracket.valid?

      ActiveRecord::Base.transaction do
        bracket.save!
        generate_matches(bracket, pairs)
      end

      bracket
    rescue ActiveRecord::RecordInvalid
      bracket
    end

    private

    def generate_matches(bracket, pairs)
      teams = pairs.dup
      teams << nil if teams.length.odd?
      n = teams.length

      (n - 1).times do |round|
        (n / 2).times do |i|
          t1 = teams[i]
          t2 = teams[n - 1 - i]
          next if t1.nil? || t2.nil?
          bracket.matches.create!(
            tournament: @tournament,
            pair1: t1,
            pair2: t2,
            round_number: round + 1,
            position: i + 1,
            status: :pending
          )
        end
        teams = [ teams[0] ] + [ teams[-1] ] + teams[1...-1]
      end
    end
  end
end
