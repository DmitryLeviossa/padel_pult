module Tournaments
  class ActivateService
    def initialize(tournament)
      @tournament = tournament
    end

    def call
      ActiveRecord::Base.transaction do
        generate_matches
        @tournament.active!
      end
      true
    rescue => e
      Rails.logger.error("Tournament activation failed: #{e.message}")
      false
    end

    private

    def generate_matches
      case @tournament.type
      when "round_robin"
        Tournaments::Matches::RoundRobinGenerator.new(@tournament).call
      when "olympic"
        Tournaments::Matches::OlympicGenerator.new(@tournament).call
      when "mixed"
        Tournaments::Matches::MixedGenerator.new(@tournament).call
      end
    end
  end
end
