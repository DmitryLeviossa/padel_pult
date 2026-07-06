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
