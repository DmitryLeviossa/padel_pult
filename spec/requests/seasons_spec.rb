require "rails_helper"

RSpec.describe "Seasons", type: :request do
  let(:owner) { create(:user) }
  let(:other_user) { create(:user) }
  let(:league) { create(:league, owner: owner) }
  let(:season) { create(:season, league: league) }

  describe "GET /leagues/:league_id/seasons/:id" do
    before { sign_in owner }

    it "renders the season name and tournaments section" do
      get league_season_path(league, season)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(season.name)
      expect(response.body).to include("Турниры сезона")
    end

    it "shows empty state when no tournaments in season" do
      get league_season_path(league, season)
      expect(response.body).to include("В этом сезоне турниров не запланировано.")
    end
  end

  describe "GET /leagues/:league_id/seasons/:id/results_pdf" do
    it "renders the print view without authentication" do
      get results_pdf_league_season_path(league, season)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(season.name)
      expect(response.body).to include("Турниры сезона")
    end
  end

  describe "GET /leagues/:league_id/seasons/:id/download_pdf" do
    before { sign_in owner }

    it "streams the generated pdf as an attachment" do
      allow_any_instance_of(SeasonResultsPdfService).to receive(:call) do
        path = Rails.root.join("tmp", "test_season_results_#{season.id}.pdf").to_s
        File.write(path, "fake-pdf-content")
        path
      end

      get download_pdf_league_season_path(league, season)

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to eq("application/pdf")
      expect(response.body).to eq("fake-pdf-content")
    end

    context "when unauthenticated" do
      before { sign_out owner }

      it "redirects to sign in" do
        get download_pdf_league_season_path(league, season)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "POST /leagues/:league_id/seasons/:id/send_pdf_to_telegram" do
    # The controller spawns Thread.new for the actual PDF generation/upload, which
    # races against the test transaction rollback. Stub it out to keep tests stable.
    before { allow_any_instance_of(SeasonsController).to receive(:deliver_pdf_to_telegram) }

    context "as owner" do
      before { sign_in owner }

      it "redirects with an alert when telegram is not configured" do
        post send_pdf_to_telegram_league_season_path(league, season)
        expect(response).to redirect_to(league_season_path(league, season))
        follow_redirect!
        expect(response.body).to include("Telegram")
      end

      it "kicks off pdf delivery to telegram when configured" do
        create(:league_telegram_setting, league: league, chat_id: "-100999", announces_thread_id: "5")

        expect_any_instance_of(SeasonsController).to receive(:deliver_pdf_to_telegram).with(
          season_id: season.id, season_name: season.name, chat_id: "-100999", thread_id: "5"
        )

        post send_pdf_to_telegram_league_season_path(league, season)
        expect(response).to redirect_to(league_season_path(league, season))
      end
    end

    context "as non-owner" do
      before { sign_in other_user }

      it "redirects with an alert" do
        post send_pdf_to_telegram_league_season_path(league, season)
        expect(response).to redirect_to(league_path(league))
      end
    end
  end

  describe "SeasonsController#deliver_pdf_to_telegram" do
    before do
      sign_in owner
      create(:league_telegram_setting, league: league, chat_id: "-100999", announces_thread_id: "5")
      # Run the background thread inline so the generation/send can be asserted synchronously.
      allow(Thread).to receive(:new) { |&block| block.call }
    end

    it "generates the pdf and sends it to telegram, then cleans up the tmp file" do
      pdf_path = Rails.root.join("tmp", "test_deliver_pdf_#{season.id}.pdf").to_s
      File.write(pdf_path, "fake-pdf-content")

      expect(SeasonResultsPdfService).to receive(:new).with(season).and_return(
        instance_double(SeasonResultsPdfService, call: pdf_path)
      )
      expect(TelegramBotService).to receive(:send_document).with(
        chat_id: "-100999", thread_id: "5", file_path: pdf_path, caption: "Результаты сезона «#{season.name}»"
      )

      post send_pdf_to_telegram_league_season_path(league, season)

      expect(File.exist?(pdf_path)).to be false
    end
  end

  describe "GET /leagues/:league_id/seasons/new" do
    context "as owner" do
      before { sign_in owner }

      it "renders the new season form" do
        get new_league_season_path(league)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Новый сезон")
      end
    end

    context "as non-owner" do
      before { sign_in other_user }

      it "redirects with alert" do
        get new_league_season_path(league)
        expect(response).to redirect_to(league_path(league))
      end
    end

    context "unauthenticated" do
      it "redirects to sign in" do
        get new_league_season_path(league)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "POST /leagues/:league_id/seasons" do
    let(:valid_params) do
      { season: { name: "Season 1", date_from: Date.today - 30, date_to: Date.today + 30 } }
    end

    context "as owner" do
      before { sign_in owner }

      it "creates a season and redirects" do
        expect {
          post league_seasons_path(league), params: valid_params
        }.to change(Season, :count).by(1)
        expect(response).to redirect_to(league_season_path(league, Season.last))
      end

      it "renders new with invalid params" do
        post league_seasons_path(league), params: { season: { name: "" } }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("Новый сезон")
      end
    end

    context "as non-owner" do
      before { sign_in other_user }

      it "does not create a season" do
        expect {
          post league_seasons_path(league), params: valid_params
        }.not_to change(Season, :count)
        expect(response).to redirect_to(league_path(league))
      end
    end
  end

  describe "PATCH /leagues/:league_id/seasons/:id" do
    context "as owner" do
      before { sign_in owner }

      it "updates the season and redirects" do
        patch league_season_path(league, season), params: { season: { name: "Updated" } }
        expect(season.reload.name).to eq("Updated")
        expect(response).to redirect_to(league_season_path(league, season))
      end

      it "renders edit with invalid params" do
        patch league_season_path(league, season), params: { season: { name: "" } }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("Редактировать сезон")
      end
    end

    context "as non-owner" do
      before { sign_in other_user }

      it "does not update the season" do
        original_name = season.name
        patch league_season_path(league, season), params: { season: { name: "Hacked" } }
        expect(season.reload.name).to eq(original_name)
        expect(response).to redirect_to(league_path(league))
      end
    end
  end

  describe "DELETE /leagues/:league_id/seasons/:id" do
    context "as owner" do
      before { sign_in owner }

      it "deletes the season and redirects" do
        season
        expect {
          delete league_season_path(league, season)
        }.to change(Season, :count).by(-1)
        expect(response).to redirect_to(league_path(league, anchor: "seasons"))
      end
    end

    context "as non-owner" do
      before { sign_in other_user }

      it "does not delete the season" do
        season
        expect {
          delete league_season_path(league, season)
        }.not_to change(Season, :count)
        expect(response).to redirect_to(league_path(league))
      end
    end
  end
end
