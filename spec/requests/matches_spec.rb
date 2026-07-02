require "rails_helper"

RSpec.describe "Matches", type: :request do
  let(:owner) { create(:user) }
  let(:other_user) { create(:user) }
  let(:league) { create(:league, owner: owner) }
  let(:tournament) { create(:tournament, :active, league: league) }

  let(:lu1) { create(:league_user, league: league) }
  let(:lu2) { create(:league_user, league: league) }
  let(:lu3) { create(:league_user, league: league) }
  let(:lu4) { create(:league_user, league: league) }
  let(:pair1) { create(:pair, tournament: tournament, player1: lu1, player2: lu2) }
  let(:pair2) { create(:pair, tournament: tournament, player1: lu3, player2: lu4) }

  # Reuse a match slot pre-created by the structure generator (position 1, round 1)
  # and assign pairs to it so we can test result submission.
  let(:match) do
    tournament.matches.find_by!(round_number: 1, position: 1).tap do |m|
      m.update_columns(pair1_id: pair1.id, pair2_id: pair2.id)
    end
  end

  before do
    # The controller spawns Thread.new for result card generation which races
    # against test transaction rollback. Stub it out to keep tests stable.
    allow_any_instance_of(MatchesController).to receive(:generate_result_card_image)
  end

  def set_params(p1, p2)
    {
      match: {
        match_sets_attributes: {
          "0" => { set_number: 1, pair1_score: p1, pair2_score: p2 }
        }
      }
    }
  end

  describe "PATCH /tournaments/:tournament_id/matches/:id" do
    context "as league owner" do
      before { sign_in owner }

      it "saves result and redirects" do
        patch tournament_match_path(tournament, match), params: set_params(6, 3)
        expect(response).to redirect_to(tournament_path(tournament))
        expect(match.reload.status).to eq("completed")
      end

      it "sets winner_id to pair1 when pair1 wins more sets" do
        patch tournament_match_path(tournament, match), params: set_params(6, 3)
        expect(match.reload.winner_id).to eq(pair1.id)
      end

      it "sets winner_id to pair2 when pair2 wins more sets" do
        patch tournament_match_path(tournament, match), params: set_params(3, 6)
        expect(match.reload.winner_id).to eq(pair2.id)
      end
    end

    context "as non-owner" do
      before { sign_in other_user }

      it "redirects with alert and does not update" do
        patch tournament_match_path(tournament, match), params: set_params(6, 3)
        expect(response).to redirect_to(tournament_path(tournament))
        expect(match.reload.status).to eq("pending")
      end
    end

    context "when tournament is completed" do
      before do
        sign_in owner
        tournament.update_columns(status: "completed")
      end

      it "redirects with alert and does not update" do
        patch tournament_match_path(tournament, match), params: set_params(6, 3)
        expect(response).to redirect_to(tournament_path(tournament))
        expect(match.reload.status).to eq("pending")
      end
    end

    context "unauthenticated" do
      it "redirects to sign in" do
        patch tournament_match_path(tournament, match), params: set_params(6, 3)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "GET /tournaments/:tournament_id/matches/:id/result_card" do
    let(:completed_match) do
      tournament.matches.find_by!(round_number: 1, position: 2).tap do |m|
        m.update_columns(pair1_id: pair1.id, pair2_id: pair2.id,
                         status: "completed", winner_id: pair1.id)
      end
    end

    it "returns 200 without authentication" do
      get result_card_tournament_match_path(tournament, completed_match)
      expect(response).to have_http_status(:ok)
    end

    it "returns 404 for a pending match" do
      get result_card_tournament_match_path(tournament, match)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /tournaments/:tournament_id/matches/:id/finish" do
    let(:one_sided_match) do
      tournament.matches.find_by!(round_number: 1, position: 3).tap do |m|
        m.update_columns(pair1_id: pair1.id, pair2_id: nil)
      end
    end

    context "as league owner" do
      before { sign_in owner }

      it "completes a match where only one pair is present" do
        post finish_tournament_match_path(tournament, one_sided_match)
        expect(response).to redirect_to(tournament_path(tournament))
        expect(one_sided_match.reload.status).to eq("completed")
        expect(one_sided_match.reload.winner_id).to eq(pair1.id)
      end

      it "does not finish a match that already has both pairs" do
        post finish_tournament_match_path(tournament, match)
        expect(response).to redirect_to(tournament_path(tournament))
        expect(match.reload.status).to eq("pending")
      end
    end

    context "as non-owner" do
      before { sign_in other_user }

      it "does not finish the match" do
        post finish_tournament_match_path(tournament, one_sided_match)
        expect(one_sided_match.reload.status).to eq("pending")
      end
    end
  end

  describe "DELETE /tournaments/:tournament_id/matches/:id" do
    before do
      sign_in owner
      allow_any_instance_of(Match).to receive(:third_place?).and_return(true)
      match  # force tournament + match creation before counting
    end

    it "deletes a third-place match and redirects" do
      expect {
        delete tournament_match_path(tournament, match)
      }.to change(Match, :count).by(-1)
      expect(response).to redirect_to(tournament_path(tournament))
    end
  end

  describe "PATCH /tournaments/:tournament_id/matches/:id/assign_pairs" do
    before { sign_in owner }

    it "assigns pairs to a match" do
      patch assign_pairs_tournament_match_path(tournament, match),
            params: { match: { pair1_id: pair1.id, pair2_id: pair2.id } }
      expect(match.reload.pair1_id).to eq(pair1.id)
      expect(match.reload.pair2_id).to eq(pair2.id)
      expect(response).to redirect_to(tournament_path(tournament))
    end
  end
end
