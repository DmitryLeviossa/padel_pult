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
        expect(response.body).to include("Турниров пока нет.")
      end
    end
  end

  describe "DELETE /users/:id" do
    let(:target_user) { create(:user) }

    context "as admin" do
      before { allow_any_instance_of(UsersController).to receive(:require_admin!) }

      it "deletes the user and redirects to users list" do
        target_user

        expect {
          delete user_path(target_user)
        }.to change(User, :count).by(-1)

        expect(response).to redirect_to(users_path)
      end

      it "also destroys associated league_users and notifications" do
        league = create(:league)
        create(:league_user, user: target_user, league: league)
        create(:notification, user: target_user)

        expect {
          delete user_path(target_user)
        }.to change(LeagueUser, :count).by(-1)
          .and change(Notification, :count).by(-1)
      end
    end

    context "as non-admin" do
      let(:non_admin) { create(:user) }
      before { sign_in non_admin }

      it "does not delete the user and redirects to root" do
        target_user

        expect {
          delete user_path(target_user)
        }.not_to change(User, :count)

        expect(response).to redirect_to(root_path)
      end
    end

    context "unauthenticated" do
      before { sign_out current_user }

      it "redirects to sign in" do
        target_user

        expect {
          delete user_path(target_user)
        }.not_to change(User, :count)

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
