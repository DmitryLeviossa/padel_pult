require "net/http"

class TelegramBotService
  API_BASE = "https://api.telegram.org"

  def self.send_photo(chat_id:, image_path:)
    token = ENV["TELEGRAM_BOT_TOKEN"]
    return unless token.present? && chat_id.present?

    uri = URI("#{API_BASE}/bot#{token}/sendPhoto")
    boundary = "----RubyBoundary#{SecureRandom.hex(8)}"
    image_data = File.binread(image_path)

    body = "--#{boundary}\r\n" \
           "Content-Disposition: form-data; name=\"chat_id\"\r\n\r\n" \
           "#{chat_id}\r\n" \
           "--#{boundary}\r\n" \
           "Content-Disposition: form-data; name=\"photo\"; filename=\"#{File.basename(image_path)}\"\r\n" \
           "Content-Type: image/png\r\n\r\n"

    Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
      request = Net::HTTP::Post.new(uri)
      request["Content-Type"] = "multipart/form-data; boundary=#{boundary}"
      request.body = body.b + image_data + "\r\n--#{boundary}--\r\n".b
      http.request(request)
    end
  end
end
