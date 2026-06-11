require 'rails_helper'

RSpec.describe GenerateMatchResultCardJob, type: :job do
  describe '#perform' do
    let(:match) { create(:match, :completed) }

    context 'when match is not completed' do
      let(:match) { create(:match) }

      it 'does not launch a browser' do
        expect(Ferrum::Browser).not_to receive(:new)
        described_class.new.perform(match.id)
      end
    end

    context 'when pair1 is missing' do
      before { match.update_columns(pair1_id: nil) }

      it 'does not launch a browser' do
        expect(Ferrum::Browser).not_to receive(:new)
        described_class.new.perform(match.id)
      end
    end

    context 'when pair2 is missing' do
      before { match.update_columns(pair2_id: nil) }

      it 'does not launch a browser' do
        expect(Ferrum::Browser).not_to receive(:new)
        described_class.new.perform(match.id)
      end
    end

    context 'when match is completed with both pairs' do
      let(:browser) { double("Ferrum::Browser") }
      let(:network) { double("Ferrum::Network") }
      let(:result_card) { double("ActiveStorage::Attached::One") }

      before do
        allow(Ferrum::Browser).to receive(:new).and_return(browser)
        allow(browser).to receive(:go_to)
        allow(browser).to receive(:network).and_return(network)
        allow(network).to receive(:wait_for_idle)
        allow(browser).to receive(:evaluate).and_return({ "x" => 0, "y" => 0, "w" => 500, "h" => 400 })
        allow(browser).to receive(:screenshot)
        allow(browser).to receive(:quit)
        allow(File).to receive(:open).and_yield(StringIO.new("fake-png"))
        allow_any_instance_of(Match).to receive(:result_card_image).and_return(result_card)
        allow(result_card).to receive(:attach)
      end

      it 'attaches the result card image to the match' do
        expect(result_card).to receive(:attach).with(
          hash_including(
            filename: "result_card_#{match.id}.png",
            content_type: "image/png"
          )
        )
        described_class.new.perform(match.id)
      end

      it 'always quits the browser even when an error occurs' do
        allow(browser).to receive(:go_to).and_raise(RuntimeError, "browser error")
        expect(browser).to receive(:quit)
        expect { described_class.new.perform(match.id) }.to raise_error(RuntimeError)
      end

      context 'when league has a telegram setting with chat_id' do
        let(:league) { match.tournament.league }
        let!(:tg_setting) do
          create(:league_telegram_setting, league: league, chat_id: "-100999", match_results_thread_id: "42")
        end

        it 'sends a photo via TelegramBotService with chat_id and thread_id' do
          expect(TelegramBotService).to receive(:send_photo).with(
            chat_id: "-100999",
            thread_id: "42",
            image_path: anything
          )
          described_class.new.perform(match.id)
        end
      end

      context 'when league has no telegram setting' do
        it 'does not call TelegramBotService' do
          expect(TelegramBotService).not_to receive(:send_photo)
          described_class.new.perform(match.id)
        end
      end

      context 'when telegram setting has no chat_id' do
        let(:league) { match.tournament.league }
        let!(:tg_setting) { create(:league_telegram_setting, league: league, chat_id: nil) }

        it 'does not call TelegramBotService' do
          expect(TelegramBotService).not_to receive(:send_photo)
          described_class.new.perform(match.id)
        end
      end
    end
  end
end
