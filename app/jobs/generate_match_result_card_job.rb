class GenerateMatchResultCardJob < ApplicationJob
  queue_as :default

  def perform(match_id)
    match = Match.includes(tournament: :league, pair1: {}, pair2: {}, match_sets: {}).find(match_id)
    return unless match.completed? && match.pair1.present? && match.pair2.present?

    host = Rails.env.production? ? ENV.fetch("APP_HOST") : "localhost:3000"
    protocol = Rails.env.production? ? "https" : "http"
    url = Rails.application.routes.url_helpers.result_card_tournament_match_url(
      match.tournament_id,
      match.id,
      host: host,
      protocol: protocol,
      source: 1
    )

    tmp_path = Rails.root.join("tmp", "result_card_#{match.id}_#{Time.current.to_i}.png").to_s

    browser = Ferrum::Browser.new(
      headless: true,
      window_size: [ 1000, 800 ],
      browser_path: browser_executable,
      browser_options: { "no-sandbox" => nil, "disable-dev-shm-usage" => nil }
    )

    begin
      browser.go_to(url)
      begin
        browser.network.wait_for_idle(timeout: 30)
      rescue Ferrum::PendingConnectionsError
        # Active Storage redirect URLs never settle; page content is already rendered
      end

      rect = browser.evaluate(
        "(() => { const r = document.querySelector('.result-card').getBoundingClientRect(); " \
        "return { x: r.x, y: r.y, w: r.width, h: r.height }; })()"
      )

      browser.screenshot(
        path: tmp_path,
        clip: { x: rect["x"].to_i, y: rect["y"].to_i, width: rect["w"].to_i, height: rect["h"].to_i }
      )

      File.open(tmp_path) do |file|
        match.result_card_image.attach(
          io: file,
          filename: "result_card_#{match.id}.png",
          content_type: "image/png"
        )
      end

      broadcast_online_update(match.tournament)

      tg = match.tournament.league.league_telegram_setting
      if tg&.chat_id.present?
        TelegramBotService.send_photo(chat_id: tg.chat_id, thread_id: tg.match_results_thread_id, image_path: tmp_path)
      end
    ensure
      browser.quit
      FileUtils.rm_f(tmp_path)
    end
  end

  private

  def broadcast_online_update(tournament)
    data = Tournaments::MatchData.new(tournament)
    Turbo::StreamsChannel.broadcast_update_to(
      "tournament_#{tournament.id}_online",
      target: "tournament_matches",
      partial: "tournaments/online_matches",
      locals: data.to_locals
    )
  end

  def browser_executable
    return ENV["BROWSER_PATH"] if ENV["BROWSER_PATH"].present? && File.exist?(ENV["BROWSER_PATH"])

    candidates = [
      "/app/.chrome-for-testing/chrome-linux64/chrome",
      "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
      "/usr/bin/google-chrome-stable",
      "/usr/bin/google-chrome",
      "/usr/bin/chromium-browser",
      "/usr/bin/chromium"
    ]
    candidates.find { |p| File.exist?(p) }
  end
end
