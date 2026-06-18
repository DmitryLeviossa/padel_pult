module Tournaments
  class ActivateService
    def initialize(tournament)
      @tournament = tournament
    end

    def call
      if @tournament.americano?
        ActiveRecord::Base.transaction do
          Tournaments::Matches::AmericanoGenerator.new(@tournament).call
          @tournament.active!
        end
      else
        @tournament.active!
      end
      true
    rescue => e
      Rails.logger.error("Tournament activation failed: #{e.message}")
      false
    end
  end
end
