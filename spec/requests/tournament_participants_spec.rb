require "rails_helper"

RSpec.describe "TournamentParticipants", type: :request do
  let(:owner) { create(:user) }
  let(:member) { create(:user) }
  let(:outsider) { create(:user) }
  let(:league) { create(:league, owner: owner) }
  # League#add_owner_as_member already creates league_user for owner on create.
  # We just need to add the regular member.
  let!(:league_member) { create(:league_user, league: league, user: member) }
  let(:tournament) { create(:tournament, :registration, league: league) }

  describe "POST /tournaments/:tournament_id/tournament_participants" do
    context "as a league member (self-register)" do
      before { sign_in member }

      it "registers the member as participant" do
        expect {
          post tournament_tournament_participants_path(tournament),
               params: { tournament_participant: {} }
        }.to change(TournamentParticipant, :count).by(1)
        expect(response).to redirect_to(tournament_path(tournament))
      end

      it "does not register when tournament is not in registration" do
        draft_t = create(:tournament, league: league, status: :draft)
        expect {
          post tournament_tournament_participants_path(draft_t),
               params: { tournament_participant: {} }
        }.not_to change(TournamentParticipant, :count)
        expect(response).to redirect_to(tournament_path(draft_t))
      end
    end

    context "as owner adding a specific member" do
      before { sign_in owner }

      it "registers the specified league_user" do
        expect {
          post tournament_tournament_participants_path(tournament),
               params: { tournament_participant: { league_user_id: league_member.id } }
        }.to change(TournamentParticipant, :count).by(1)

        tp = TournamentParticipant.last
        expect(tp.league_user).to eq(league_member)
      end
    end

    context "as outsider not in league" do
      before { sign_in outsider }

      it "does not register and redirects" do
        expect {
          post tournament_tournament_participants_path(tournament),
               params: { tournament_participant: {} }
        }.not_to change(TournamentParticipant, :count)
        expect(response).to redirect_to(tournament_path(tournament))
      end
    end

    context "unauthenticated" do
      it "redirects to sign in" do
        post tournament_tournament_participants_path(tournament),
             params: { tournament_participant: {} }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "DELETE /tournaments/:tournament_id/tournament_participants/:id" do
    let!(:participant) { create(:tournament_participant, tournament: tournament, league_user: league_member) }

    context "as league owner" do
      before { sign_in owner }

      it "removes the participant and redirects" do
        expect {
          delete tournament_tournament_participant_path(tournament, participant)
        }.to change(TournamentParticipant, :count).by(-1)
        expect(response).to redirect_to(tournament_path(tournament))
      end

      it "does not allow removal when tournament is not in registration" do
        active_t = create(:tournament, :active, league: league)
        tp = create(:tournament_participant, tournament: active_t, league_user: league_member)
        expect {
          delete tournament_tournament_participant_path(active_t, tp)
        }.not_to change(TournamentParticipant, :count)
        expect(response).to redirect_to(tournament_path(active_t))
      end
    end

    context "as non-owner" do
      before { sign_in member }

      it "does not remove the participant" do
        expect {
          delete tournament_tournament_participant_path(tournament, participant)
        }.not_to change(TournamentParticipant, :count)
        expect(response).to redirect_to(tournament_path(tournament))
      end
    end
  end
end
