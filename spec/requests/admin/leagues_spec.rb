require "rails_helper"

RSpec.describe "Admin::Leagues", type: :request do
  let(:admin) { create(:user, id: 1) }
  let(:other) { create(:user) }
  let(:league) { create(:league) }

  describe "PATCH /admin/leagues/:id" do
    context "as admin" do
      before { sign_in admin }

      it "updates tournaments_quota and returns 204" do
        patch admin_league_path(league), params: { league: { tournaments_quota: 10 } }
        expect(response).to have_http_status(:no_content)
        expect(league.reload.tournaments_quota).to eq(10)
      end

      it "returns 422 for negative quota" do
        patch admin_league_path(league), params: { league: { tournaments_quota: -1 } }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "allows quota of 0" do
        patch admin_league_path(league), params: { league: { tournaments_quota: 0 } }
        expect(response).to have_http_status(:no_content)
        expect(league.reload.tournaments_quota).to eq(0)
      end
    end

    context "as non-admin" do
      before { sign_in other }

      it "redirects to root" do
        patch admin_league_path(league), params: { league: { tournaments_quota: 10 } }
        expect(response).to redirect_to(root_path)
      end
    end

    context "as guest" do
      it "redirects to sign in" do
        patch admin_league_path(league), params: { league: { tournaments_quota: 10 } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
