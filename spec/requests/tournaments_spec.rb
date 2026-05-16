require "rails_helper"

RSpec.describe "Tournaments", type: :request do
  let(:owner) { create(:user) }
  let(:other_user) { create(:user) }
  let(:league) { create(:league, owner: owner) }
  let(:draft_tournament) { create(:tournament, league: league) }
  let(:active_tournament) { create(:tournament, :active, league: league) }

  describe "GET /tournaments/:id/edit" do
    context "as owner" do
      before { sign_in owner }

      it "returns 200 for draft tournament" do
        get edit_tournament_path(draft_tournament)
        expect(response).to have_http_status(:ok)
      end

      it "redirects to tournament for non-draft tournament" do
        get edit_tournament_path(active_tournament)
        expect(response).to redirect_to(tournament_path(active_tournament))
      end
    end

    context "as non-owner" do
      before { sign_in other_user }

      it "redirects to league" do
        get edit_tournament_path(draft_tournament)
        expect(response).to redirect_to(league_path(draft_tournament.league))
      end
    end

    context "unauthenticated" do
      it "redirects to sign in" do
        get edit_tournament_path(draft_tournament)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "PATCH /tournaments/:id" do
    context "as owner" do
      before { sign_in owner }

      it "updates draft tournament and redirects" do
        patch tournament_path(draft_tournament), params: { tournament: { name: "Updated Name" } }
        expect(response).to redirect_to(tournament_path(draft_tournament))
        expect(draft_tournament.reload.name).to eq("Updated Name")
      end

      it "does not update non-draft tournament" do
        original_name = active_tournament.name
        patch tournament_path(active_tournament), params: { tournament: { name: "Changed" } }
        expect(response).to redirect_to(tournament_path(active_tournament))
        expect(active_tournament.reload.name).to eq(original_name)
      end

      it "re-renders edit on validation failure" do
        patch tournament_path(draft_tournament), params: {
          tournament: { placement_points: [ { from: 0, to: 0, points: 0 } ] }
        }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "as non-owner" do
      before { sign_in other_user }

      it "does not update tournament and redirects to league" do
        original_name = draft_tournament.name
        patch tournament_path(draft_tournament), params: { tournament: { name: "Changed" } }
        expect(response).to redirect_to(league_path(draft_tournament.league))
        expect(draft_tournament.reload.name).to eq(original_name)
      end
    end
  end
end
