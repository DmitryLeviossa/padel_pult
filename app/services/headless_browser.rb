module HeadlessBrowser
  EXECUTABLE_CANDIDATES = [
    "/app/.chrome-for-testing/chrome-linux64/chrome",
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
    "/usr/bin/google-chrome-stable",
    "/usr/bin/google-chrome",
    "/usr/bin/chromium-browser",
    "/usr/bin/chromium"
  ].freeze

  def self.launch(window_size: [ 1000, 800 ])
    browser = Ferrum::Browser.new(
      headless: true,
      window_size: window_size,
      browser_path: executable_path,
      browser_options: { "no-sandbox" => nil, "disable-dev-shm-usage" => nil }
    )

    yield browser
  ensure
    browser&.quit
  end

  def self.visit(browser, url, timeout: 30)
    browser.go_to(url)
    begin
      browser.network.wait_for_idle(timeout: timeout)
    rescue Ferrum::PendingConnectionsError
      # Active Storage redirect URLs never settle; page content is already rendered
    end
  end

  def self.executable_path
    return ENV["BROWSER_PATH"] if ENV["BROWSER_PATH"].present? && File.exist?(ENV["BROWSER_PATH"])

    EXECUTABLE_CANDIDATES.find { |p| File.exist?(p) }
  end
end
