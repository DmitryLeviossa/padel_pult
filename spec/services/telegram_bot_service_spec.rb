require "rails_helper"

RSpec.describe TelegramBotService do
  let(:token) { "test_token" }
  let(:chat_id) { "-100123456" }
  let(:image_path) { Rails.root.join("spec/fixtures/files/test_image.png").to_s }

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("TELEGRAM_BOT_TOKEN").and_return(token)
    allow(File).to receive(:binread).with(image_path).and_return("fake-image-data")
  end

  describe ".send_photo" do
    context "when token is missing" do
      before { allow(ENV).to receive(:[]).with("TELEGRAM_BOT_TOKEN").and_return(nil) }

      it "returns without making an HTTP request" do
        expect(Net::HTTP).not_to receive(:start)
        described_class.send_photo(chat_id: chat_id, image_path: image_path)
      end
    end

    context "when chat_id is missing" do
      it "returns without making an HTTP request" do
        expect(Net::HTTP).not_to receive(:start)
        described_class.send_photo(chat_id: nil, image_path: image_path)
      end
    end

    context "with chat_id only (no thread_id)" do
      it "sends a multipart request without message_thread_id" do
        stub = instance_double(Net::HTTP)
        allow(Net::HTTP).to receive(:start).and_yield(stub)

        response = instance_double(Net::HTTPResponse)
        expect(stub).to receive(:request) do |req|
          expect(req.body).to include("chat_id")
          expect(req.body).not_to include("message_thread_id")
          response
        end

        described_class.send_photo(chat_id: chat_id, image_path: image_path)
      end
    end

    context "with thread_id provided" do
      it "sends a multipart request with message_thread_id" do
        stub = instance_double(Net::HTTP)
        allow(Net::HTTP).to receive(:start).and_yield(stub)

        response = instance_double(Net::HTTPResponse)
        expect(stub).to receive(:request) do |req|
          expect(req.body).to include("chat_id")
          expect(req.body).to include("message_thread_id")
          expect(req.body).to include("99")
          response
        end

        described_class.send_photo(chat_id: chat_id, thread_id: "99", image_path: image_path)
      end
    end
  end
end
