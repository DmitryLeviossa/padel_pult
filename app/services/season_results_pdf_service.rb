class SeasonResultsPdfService
  def initialize(season)
    @season = season
  end

  def call
    tmp_path = Rails.root.join("tmp", "season_results_#{@season.id}_#{Time.current.to_i}.pdf").to_s

    HeadlessBrowser.launch(window_size: [ 850, 1200 ]) do |browser|
      HeadlessBrowser.visit(browser, results_pdf_url)
      browser.pdf(path: tmp_path, format: :A4, print_background: true, scale: 0.84)
    end

    tmp_path
  end

  private

  def results_pdf_url
    host = Rails.env.production? ? ENV.fetch("APP_HOST") : "localhost:3000"
    protocol = Rails.env.production? ? "https" : "http"

    Rails.application.routes.url_helpers.results_pdf_league_season_url(
      @season.league_id,
      @season.id,
      host: host,
      protocol: protocol
    )
  end
end
