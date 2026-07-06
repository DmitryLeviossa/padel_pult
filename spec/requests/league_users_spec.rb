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
        expect(response.body).to include("Добавить нового участника")
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

  describe "GET /leagues/:league_id/league_users/:id/edit" do
    let(:pending_user) { create(:user, :invited) }
    let!(:league_user) { create(:league_user, league: league, user: pending_user) }

    context "as owner" do
      before { sign_in owner }

      it "renders the edit form for a pending user" do
        get edit_league_league_user_path(league, league_user)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Редактировать участника")
        expect(response.body).to include(pending_user.first_name)
      end

      it "redirects away for a registered user" do
        registered = create(:user)
        lu = create(:league_user, league: league, user: registered)
        get edit_league_league_user_path(league, lu)
        expect(response).to redirect_to(league_path(league, anchor: "league-users"))
      end
    end

    context "as non-owner" do
      before { sign_in other_user }

      it "redirects away" do
        get edit_league_league_user_path(league, league_user)
        expect(response).to redirect_to(leagues_path)
      end
    end
  end

  describe "PATCH /leagues/:league_id/league_users/:id (user name update)" do
    let(:pending_user) { create(:user, :invited, first_name: "Old", last_name: "Name") }
    let!(:league_user) { create(:league_user, league: league, user: pending_user) }

    context "as owner" do
      before { sign_in owner }

      it "updates first_name and last_name of a pending user" do
        patch league_league_user_path(league, league_user), params: { user: { first_name: "New", last_name: "Name" } }
        expect(pending_user.reload.first_name).to eq("New")
        expect(response).to redirect_to(league_path(league, anchor: "league-users"))
      end

      it "does not update a registered user" do
        registered = create(:user, first_name: "Alice")
        lu = create(:league_user, league: league, user: registered)
        patch league_league_user_path(league, lu), params: { user: { first_name: "Hacked" } }
        expect(registered.reload.first_name).to eq("Alice")
        expect(response).to redirect_to(league_path(league, anchor: "league-users"))
      end
    end

    context "as non-owner" do
      before { sign_in other_user }

      it "does not update and redirects" do
        patch league_league_user_path(league, league_user), params: { user: { first_name: "X" } }
        expect(pending_user.reload.first_name).to eq("Old")
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
        expect(response.body).to include("Добавить нового участника")
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
