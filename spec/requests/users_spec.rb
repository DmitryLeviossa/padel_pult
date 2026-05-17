require "rails_helper"

RSpec.describe "Users", type: :request do
  let(:current_user) { create(:user) }
  let(:other_user) { create(:user) }

  before { sign_in current_user }

  describe "GET /users/:id" do
    it "returns 200" do
      get user_path(other_user)
      expect(response).to have_http_status(:ok)
    end

    it "shows user full name" do
      get user_path(other_user)
      expect(response.body).to include(other_user.full_name)
    end

    context "when user has tournament history" do
      let(:league) { create(:league) }
      let(:tournament) { create(:tournament, league: league, status: :completed) }
      let(:lu1) { create(:league_user, user: other_user, league: league) }
      let(:lu2) { create(:league_user, league: league) }

      before { create(:pair, tournament: tournament, player1: lu1, player2: lu2) }

      it "shows the tournament name" do
        get user_path(other_user)
        expect(response.body).to include(tournament.name)
      end

      it "shows the partner name" do
        get user_path(other_user)
        expect(response.body).to include(lu2.full_name)
      end
    end

    context "when user has no tournament history" do
      it "shows no history message" do
        get user_path(other_user)
        expect(response.body).to include(I18n.t("users.show.no_history"))
      end
    end
  end
end
