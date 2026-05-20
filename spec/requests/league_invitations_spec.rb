require "rails_helper"

RSpec.describe "LeagueInvitations", type: :request do
  let(:owner) { create(:user) }
  let(:league) { create(:league, owner: owner) }
  let(:invitee) { create(:user) }

  describe "POST /leagues/:league_id/league_invitations" do
    context "as league owner" do
      before { sign_in owner }

      it "creates pending invitations for selected users" do
        post league_league_invitations_path(league), params: {
          league_invitation: { invited_user_ids: [invitee.id] }
        }
        expect(response).to redirect_to(league_path(league, anchor: "league-users"))
        expect(LeagueInvitation.count).to eq(1)
        expect(LeagueInvitation.last).to have_attributes(
          status: "pending",
          invited_user: invitee,
          invited_by: owner
        )
      end

      it "can invite multiple users at once" do
        other_invitee = create(:user)
        post league_league_invitations_path(league), params: {
          league_invitation: { invited_user_ids: [invitee.id, other_invitee.id] }
        }
        expect(LeagueInvitation.count).to eq(2)
      end

      it "silently skips duplicate invitations" do
        create(:league_invitation, league: league, invited_user: invitee, invited_by: owner)
        expect {
          post league_league_invitations_path(league), params: {
            league_invitation: { invited_user_ids: [invitee.id] }
          }
        }.not_to change(LeagueInvitation, :count)
      end

      it "silently skips existing league members" do
        member = create(:user)
        league.league_users.create!(user: member)
        expect {
          post league_league_invitations_path(league), params: {
            league_invitation: { invited_user_ids: [member.id] }
          }
        }.not_to change(LeagueInvitation, :count)
      end

      it "redirects with alert when no users selected" do
        post league_league_invitations_path(league), params: {
          league_invitation: { invited_user_ids: [] }
        }
        expect(response).to redirect_to(league_path(league, anchor: "league-users"))
        follow_redirect!
        expect(response.body).to include("Выберите хотя бы одного игрока.")
      end
    end

    context "as non-owner" do
      before { sign_in invitee }

      it "redirects to leagues" do
        post league_league_invitations_path(league), params: {
          league_invitation: { invited_user_ids: [invitee.id] }
        }
        expect(response).to redirect_to(leagues_path)
        expect(LeagueInvitation.count).to eq(0)
      end
    end
  end

  describe "PATCH /league_invitations/:id" do
    let!(:invitation) { create(:league_invitation, league: league, invited_user: invitee, invited_by: owner) }

    context "as the invited user" do
      before { sign_in invitee }

      it "accepts the invitation and adds user to league" do
        patch league_invitation_path(invitation), params: { status: "accepted" }
        expect(response).to redirect_to(league_path(league))
        expect(invitation.reload.status).to eq("accepted")
        expect(league.users.reload).to include(invitee)
      end

      it "dismisses the invitation" do
        patch league_invitation_path(invitation), params: { status: "dismissed" }
        expect(invitation.reload.status).to eq("dismissed")
        expect(league.users.reload).not_to include(invitee)
      end
    end

    context "as another user" do
      let(:other_user) { create(:user) }
      before { sign_in other_user }

      it "cannot act on someone else's invitation" do
        patch league_invitation_path(invitation), params: { status: "accepted" }
        expect(response).to redirect_to(root_path)
        expect(invitation.reload.status).to eq("pending")
      end
    end

    context "on an already-accepted invitation" do
      before do
        sign_in invitee
        invitation.accepted!
      end

      it "redirects to root as not found" do
        patch league_invitation_path(invitation), params: { status: "dismissed" }
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
