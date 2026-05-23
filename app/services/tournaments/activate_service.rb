module Tournaments
  class ActivateService
    def initialize(tournament)
      @tournament = tournament
    end

    def call
      @tournament.active!
      true
    rescue => e
      Rails.logger.error("Tournament activation failed: #{e.message}")
      false
    end
  end
end
