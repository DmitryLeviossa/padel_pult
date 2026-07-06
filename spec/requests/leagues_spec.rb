require "rails_helper"

RSpec.describe "Leagues", type: :request do
  let(:owner) { create(:user) }
  let(:member) { create(:user) }
  let(:league) { create(:league, owner: owner) }

  before { league.league_users.create!(user: member) }

  describe "GET /leagues" do
    context "as owner" do
      before { sign_in owner }

      it "returns 200 and shows the leagues heading" do
        get leagues_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Лиги")
      end

      it "lists leagues the user belongs to" do
        get leagues_path
        expect(response.body).to include(league.name)
      end

      it "shows empty state when user has no leagues" do
        League.destroy_all
        get leagues_path
        expect(response.body).to include("Лиг пока нет.")
      end
    end

    context "unauthenticated" do
      it "redirects to sign in" do
        get leagues_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "GET /leagues/:id" do
    context "as owner" do
      before { sign_in owner }

      it "renders the league name and tabs" do
        get league_path(league)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include(league.name)
        expect(response.body).to include("Турниры")
        expect(response.body).to include("Участники")
      end

      it "shows empty tournaments message by default" do
        get league_path(league)
        expect(response.body).to include("Турниров пока нет.")
      end

      it "lists tournaments belonging to the league" do
        tournament = create(:tournament, league: league)
        get league_path(league)
        expect(response.body).to include(tournament.name)
      end
    end

    context "as member" do
      before { sign_in member }

      it "returns 200 and shows the league name" do
        get league_path(league)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include(league.name)
      end
    end

    context "unauthenticated" do
      it "redirects to sign in" do
        get league_path(league)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "GET /leagues/new" do
    context "authenticated" do
      before { sign_in owner }

      it "renders the new league form" do
        get new_league_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Новая лига")
        expect(response.body).to include("Создать лигу")
      end
    end

    context "unauthenticated" do
      it "redirects to sign in" do
        get new_league_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "DELETE /leagues/:id/leave" do
    context "as owner" do
      before { sign_in owner }

      it "redirects back with alert and does not remove owner from league" do
        delete leave_league_path(league)
        expect(response).to redirect_to(league)
        follow_redirect!
        expect(response.body).to include("Владелец не может покинуть лигу.")
        expect(league.users.reload).to include(owner)
      end
    end

    context "as regular member" do
      before { sign_in member }

      it "removes the member and redirects" do
        delete leave_league_path(league)
        expect(response).to redirect_to(league)
        expect(league.users.reload).not_to include(member)
      end
    end
  end
end
