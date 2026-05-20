require "rails_helper"

RSpec.describe "Leagues::LeagueUsers", type: :request do
  let(:owner) { create(:user) }
  let(:other_user) { create(:user) }
  let(:league) { create(:league, owner: owner) }

  describe "GET /leagues/:league_id/league_users/new" do
    context "as owner" do
      before { sign_in owner }

      it "renders the new form" do
        get new_league_league_user_path(league)
        expect(response).to have_http_status(:ok)
      end
    end

    context "as non-owner" do
      before { sign_in other_user }

      it "redirects away" do
        get new_league_league_user_path(league)
        expect(response).to redirect_to(leagues_path)
      end
    end
  end

  describe "POST /leagues/:league_id/league_users" do
    context "as owner" do
      before { league; sign_in owner }

      it "creates a pending user and adds them to the league" do
        expect {
          post league_league_users_path(league), params: { user: { first_name: "Алекс", last_name: "Смирнов", gender: "male" } }
        }.to change(User, :count).by(1).and change(LeagueUser, :count).by(1)

        new_user = User.order(:created_at).last
        expect(new_user.pending_invitation?).to be true
        expect(new_user.leagues).to include(league)
        expect(response).to redirect_to(league_path(league, anchor: "league-users"))
      end

      it "renders new with errors given invalid params" do
        post league_league_users_path(league), params: { user: { first_name: "", last_name: "", gender: nil } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "as non-owner" do
      before { league; sign_in other_user }

      it "does not create a user and redirects" do
        expect {
          post league_league_users_path(league), params: { user: { first_name: "X", last_name: "Y", gender: "male" } }
        }.not_to change(User, :count)
        expect(response).to redirect_to(leagues_path)
      end
    end
  end
end
