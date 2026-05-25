require "rails_helper"

RSpec.describe Tournaments::ActivateService do
  let(:league) { create(:league) }

  describe "#call" do
    context "when tournament is in registration status" do
      let(:tournament) { create(:tournament, :registration, league: league) }

      it "changes status to active" do
        described_class.new(tournament).call
        expect(tournament.reload.status).to eq("active")
      end

      it "returns true" do
        expect(described_class.new(tournament).call).to be true
      end
    end

    context "when activation raises an unexpected error" do
      let(:tournament) { create(:tournament, :registration, league: league) }

      it "returns false and logs the error" do
        allow(tournament).to receive(:active!).and_raise(StandardError, "unexpected")
        expect(described_class.new(tournament).call).to be false
      end
    end
  end
end
