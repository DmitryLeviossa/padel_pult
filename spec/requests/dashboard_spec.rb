require "rails_helper"

RSpec.describe "Dashboard", type: :request do
  let(:user) { create(:user) }

  describe "GET /" do
    context "when authenticated" do
      before { sign_in user }

      it "returns 200" do
        get root_path
        expect(response).to have_http_status(:ok)
      end

      it "shows leagues the user belongs to" do
        league = create(:league, owner: user)
        get root_path
        expect(response.body).to include(league.name)
      end
    end

    context "when unauthenticated" do
      it "redirects to sign in" do
        get root_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
