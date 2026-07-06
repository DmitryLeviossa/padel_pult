require "rails_helper"

RSpec.describe "Invitations", type: :request do
  let(:invited_user) { create(:user, :invited) }
  let(:token) { invited_user.invitation_token }

  describe "GET /invitations/:token" do
    it "renders the completion form for a valid token" do
      get invitation_path(token)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Завершите регистрацию")
      expect(response.body).to include(invited_user.full_name)
    end

    it "redirects for an invalid token" do
      get invitation_path("invalid-token")
      expect(response).to redirect_to(root_path)
    end
  end

  describe "PATCH /invitations/:token" do
    context "with valid params" do
      it "sets email and password, clears token, and signs in user" do
        patch invitation_path(token), params: { user: { email: "new@example.com", password: "password123", password_confirmation: "password123" } }

        expect(response).to redirect_to(root_path)
        invited_user.reload
        expect(invited_user.email).to eq("new@example.com")
        expect(invited_user.invitation_token).to be_nil
      end
    end

    context "with invalid params" do
      it "re-renders the form" do
        patch invitation_path(token), params: { user: { email: "bad-email", password: "short", password_confirmation: "mismatch" } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "with an invalid token" do
      it "redirects to root" do
        patch invitation_path("bogus"), params: { user: { email: "x@x.com", password: "password123", password_confirmation: "password123" } }
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
