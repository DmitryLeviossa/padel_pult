require "rails_helper"

RSpec.describe "Leagues::LeagueTelegramSettings", type: :request do
  let(:owner) { create(:user) }
  let(:other_user) { create(:user) }
  let(:league) { create(:league, owner: owner) }

  describe "POST /leagues/:league_id/league_telegram_setting" do
    let(:valid_params) do
      { league_telegram_setting: { chat_id: "-100999", match_results_thread_id: "10", announces_thread_id: "20" } }
    end

    context "as owner" do
      before { sign_in owner }

      it "creates a telegram setting and redirects to settings tab" do
        expect {
          post league_league_telegram_setting_path(league), params: valid_params
        }.to change(LeagueTelegramSetting, :count).by(1)

        setting = league.reload.league_telegram_setting
        expect(setting.chat_id).to eq("-100999")
        expect(setting.match_results_thread_id).to eq("10")
        expect(setting.announces_thread_id).to eq("20")
        expect(response).to redirect_to(league_path(league, tab: "settings", anchor: "settings"))
      end
    end

    context "as non-owner" do
      before { sign_in other_user }

      it "does not create a setting and redirects" do
        expect {
          post league_league_telegram_setting_path(league), params: valid_params
        }.not_to change(LeagueTelegramSetting, :count)
        expect(response).to redirect_to(leagues_path)
      end
    end
  end

  describe "PATCH /leagues/:league_id/league_telegram_setting" do
    let!(:setting) { create(:league_telegram_setting, league: league, chat_id: "-100old") }

    context "as owner" do
      before { sign_in owner }

      it "updates the telegram setting and redirects to settings tab" do
        patch league_league_telegram_setting_path(league),
              params: { league_telegram_setting: { chat_id: "-100new", match_results_thread_id: "42" } }

        expect(setting.reload.chat_id).to eq("-100new")
        expect(setting.reload.match_results_thread_id).to eq("42")
        expect(response).to redirect_to(league_path(league, tab: "settings", anchor: "settings"))
      end
    end

    context "as non-owner" do
      before { sign_in other_user }

      it "does not update the setting and redirects" do
        patch league_league_telegram_setting_path(league),
              params: { league_telegram_setting: { chat_id: "-100hacked" } }

        expect(setting.reload.chat_id).to eq("-100old")
        expect(response).to redirect_to(leagues_path)
      end
    end
  end
end
