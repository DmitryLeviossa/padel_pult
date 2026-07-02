require "rails_helper"

RSpec.describe "Clubs", type: :request do
  let(:user) { create(:user) }
  let!(:club1) { create(:club, name: "Alpha Club") }
  let!(:club2) { create(:club, name: "Beta Club") }

  before { sign_in user }

  describe "GET /clubs" do
    it "returns 200" do
      get clubs_path
      expect(response).to have_http_status(:ok)
    end

    it "lists all clubs" do
      get clubs_path
      expect(response.body).to include("Alpha Club", "Beta Club")
    end
  end

  describe "GET /clubs/:id" do
    it "returns 200 for an existing club" do
      get club_path(club1)
      expect(response).to have_http_status(:ok)
    end

    it "returns 404 for a missing club" do
      get club_path(id: 0)
      expect(response).to have_http_status(:not_found)
    end
  end
end
