require "rails_helper"

RSpec.describe SeasonResultsPdfService do
  let(:league) { create(:league) }
  let(:season) { create(:season, league: league) }
  let(:browser) { double("Ferrum::Browser") }
  let(:network) { double("Ferrum::Network") }

  before do
    allow(Ferrum::Browser).to receive(:new).and_return(browser)
    allow(browser).to receive(:go_to)
    allow(browser).to receive(:network).and_return(network)
    allow(network).to receive(:wait_for_idle)
    allow(browser).to receive(:pdf)
    allow(browser).to receive(:quit)
  end

  describe "#call" do
    it "visits the season results_pdf url and renders a pdf to a tmp path" do
      expect(browser).to receive(:go_to).with(
        "http://localhost:3000/leagues/#{league.id}/seasons/#{season.id}/results_pdf"
      )
      expect(browser).to receive(:pdf).with(
        hash_including(format: :A4, print_background: true)
      )

      path = described_class.new(season).call
      expect(path).to include("season_results_#{season.id}")
      expect(path).to end_with(".pdf")
    end

    it "always quits the browser even when an error occurs" do
      allow(browser).to receive(:go_to).and_raise(RuntimeError, "browser error")
      expect(browser).to receive(:quit)
      expect { described_class.new(season).call }.to raise_error(RuntimeError)
    end
  end
end
