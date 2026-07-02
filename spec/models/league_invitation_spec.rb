require "rails_helper"

RSpec.describe LeagueInvitation, type: :model do
  let(:league) { create(:league) }
  let(:inviter) { create(:user) }
  let(:invitee) { create(:user) }

  describe "status enum" do
    it "defaults to pending" do
      inv = build(:league_invitation, league: league, invited_by: inviter, invited_user: invitee)
      expect(inv).to be_pending
    end

    it "can be accepted or dismissed" do
      inv = create(:league_invitation, league: league, invited_by: inviter, invited_user: invitee)
      inv.accepted!
      expect(inv).to be_accepted
      inv.dismissed!
      expect(inv).to be_dismissed
    end
  end

  describe "uniqueness" do
    it "prevents duplicate invitation for the same user in the same league" do
      create(:league_invitation, league: league, invited_by: inviter, invited_user: invitee)
      dup = build(:league_invitation, league: league, invited_by: inviter, invited_user: invitee)
      expect(dup).not_to be_valid
      expect(dup.errors[:invited_user_id]).to be_present
    end
  end

  describe "invited_user_not_already_member" do
    it "is invalid when the user is already a member of the league" do
      league.league_users.create!(user: invitee)
      inv = build(:league_invitation, league: league, invited_by: inviter, invited_user: invitee)
      expect(inv).not_to be_valid
      expect(inv.errors[:invited_user]).to include("уже является участником этой лиги")
    end

    it "is valid when the user is not a member" do
      inv = build(:league_invitation, league: league, invited_by: inviter, invited_user: invitee)
      expect(inv).to be_valid
    end
  end
end
