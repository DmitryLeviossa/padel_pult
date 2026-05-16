require "rails_helper"

RSpec.describe "Leagues", type: :request do
  let(:owner) { create(:user) }
  let(:member) { create(:user) }
  let(:league) { create(:league, owner: owner) }

  before { league.league_users.create!(user: member) }

  describe "DELETE /leagues/:id/leave" do
    context "as owner" do
      before { sign_in owner }

      it "redirects back with alert and does not remove owner from league" do
        delete leave_league_path(league)
        expect(response).to redirect_to(league)
        follow_redirect!
        expect(response.body).to include(I18n.t("leagues.show.owner_cannot_leave"))
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
