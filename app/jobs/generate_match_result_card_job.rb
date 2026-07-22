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

    HeadlessBrowser.launch do |browser|
      HeadlessBrowser.visit(browser, url)

      rect = browser.evaluate(
        "(() => { const r = document.querySelector('.result-card').getBoundingClientRect(); " \
        "return { x: r.x, y: r.y, w: r.width, h: r.height }; })()"
      )

      browser.screenshot(
        path: tmp_path,
        clip: { x: rect["x"].to_i, y: rect["y"].to_i, width: rect["w"].to_i, height: rect["h"].to_i }
      )
    end

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
    FileUtils.rm_f(tmp_path) if tmp_path
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
end
