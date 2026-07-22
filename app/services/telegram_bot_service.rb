require "net/http"

class TelegramBotService
  API_BASE = "https://api.telegram.org"

  def self.send_message(chat_id:, text:, thread_id: nil)
    token = ENV["TELEGRAM_BOT_TOKEN"]
    return unless token.present? && chat_id.present?

    uri = URI("#{API_BASE}/bot#{token}/sendMessage")
    params = { chat_id: chat_id, text: text }
    params[:message_thread_id] = thread_id if thread_id.present?

    Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
      request = Net::HTTP::Post.new(uri)
      request.content_type = "application/json"
      request.body = params.to_json
      http.request(request)
    end
  end

  def self.send_photo(chat_id:, image_path:, thread_id: nil)
    token = ENV["TELEGRAM_BOT_TOKEN"]
    return unless token.present? && chat_id.present?

    uri = URI("#{API_BASE}/bot#{token}/sendPhoto")
    boundary = "----RubyBoundary#{SecureRandom.hex(8)}"
    image_data = File.binread(image_path)

    body = "--#{boundary}\r\n" \
           "Content-Disposition: form-data; name=\"chat_id\"\r\n\r\n" \
           "#{chat_id}\r\n"

    if thread_id.present?
      body += "--#{boundary}\r\n" \
              "Content-Disposition: form-data; name=\"message_thread_id\"\r\n\r\n" \
              "#{thread_id}\r\n"
    end

    body += "--#{boundary}\r\n" \
            "Content-Disposition: form-data; name=\"photo\"; filename=\"#{File.basename(image_path)}\"\r\n" \
            "Content-Type: image/png\r\n\r\n"

    Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
      request = Net::HTTP::Post.new(uri)
      request["Content-Type"] = "multipart/form-data; boundary=#{boundary}"
      request.body = body.b + image_data + "\r\n--#{boundary}--\r\n".b
      http.request(request)
    end
  end

  def self.send_document(chat_id:, file_path:, thread_id: nil, caption: nil)
    token = ENV["TELEGRAM_BOT_TOKEN"]
    return unless token.present? && chat_id.present?

    uri = URI("#{API_BASE}/bot#{token}/sendDocument")
    boundary = "----RubyBoundary#{SecureRandom.hex(8)}"
    file_data = File.binread(file_path)

    body = "--#{boundary}\r\n" \
           "Content-Disposition: form-data; name=\"chat_id\"\r\n\r\n" \
           "#{chat_id}\r\n"

    if thread_id.present?
      body += "--#{boundary}\r\n" \
              "Content-Disposition: form-data; name=\"message_thread_id\"\r\n\r\n" \
              "#{thread_id}\r\n"
    end

    if caption.present?
      body += "--#{boundary}\r\n" \
              "Content-Disposition: form-data; name=\"caption\"\r\n\r\n" \
              "#{caption}\r\n"
    end

    body += "--#{boundary}\r\n" \
            "Content-Disposition: form-data; name=\"document\"; filename=\"#{File.basename(file_path)}\"\r\n" \
            "Content-Type: application/pdf\r\n\r\n"

    Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
      request = Net::HTTP::Post.new(uri)
      request["Content-Type"] = "multipart/form-data; boundary=#{boundary}"
      request.body = body.b + file_data + "\r\n--#{boundary}--\r\n".b
      http.request(request)
    end
  end
end
