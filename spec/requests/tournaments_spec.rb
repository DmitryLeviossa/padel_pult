require "rails_helper"

RSpec.describe "Tournaments", type: :request do
  let(:owner) { create(:user) }
  let(:other_user) { create(:user) }
  let(:league) { create(:league, owner: owner) }
  let(:draft_tournament) { create(:tournament, league: league) }
  let(:active_tournament) { create(:tournament, :active, league: league) }

  describe "GET /tournaments/:id" do
    context "as owner" do
      before { sign_in owner }

      it "renders the tournament name and status" do
        get tournament_path(draft_tournament)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include(draft_tournament.name)
        expect(response.body).to include("Черновик")
      end

      it "shows empty pairs message when no pairs registered" do
        get tournament_path(draft_tournament)
        expect(response.body).to include("Пар пока нет.")
      end
    end

    context "as non-owner" do
      before { sign_in other_user }

      it "returns 200" do
        get tournament_path(draft_tournament)
        expect(response).to have_http_status(:ok)
      end
    end

    context "unauthenticated" do
      it "redirects to sign in" do
        get tournament_path(draft_tournament)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "DELETE /tournaments/:id" do
    context "as owner" do
      before { sign_in owner }

      it "deletes draft tournament and redirects to league" do
        delete tournament_path(draft_tournament)
        expect(response).to redirect_to(league_path(league, anchor: "tournaments"))
        expect(Tournament.exists?(draft_tournament.id)).to be false
      end

      it "does not delete non-draft tournament" do
        delete tournament_path(active_tournament)
        expect(response).to redirect_to(tournament_path(active_tournament))
        expect(Tournament.exists?(active_tournament.id)).to be true
      end
    end

    context "as non-owner" do
      before { sign_in other_user }

      it "does not delete tournament and redirects to league" do
        delete tournament_path(draft_tournament)
        expect(response).to redirect_to(league_path(draft_tournament.league))
        expect(Tournament.exists?(draft_tournament.id)).to be true
      end
    end

    context "unauthenticated" do
      it "redirects to sign in" do
        delete tournament_path(draft_tournament)
        expect(response).to redirect_to(new_user_session_path)
        expect(Tournament.exists?(draft_tournament.id)).to be true
      end
    end
  end

  describe "GET /tournaments/:id/fill_results" do
    context "as owner" do
      before { sign_in owner }

      it "returns 200 for active tournament" do
        get fill_results_tournament_path(active_tournament)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Результаты:")
        expect(response.body).to include(active_tournament.name)
      end

      it "redirects to tournament for non-active tournament" do
        get fill_results_tournament_path(draft_tournament)
        expect(response).to redirect_to(tournament_path(draft_tournament))
      end
    end

    context "as non-owner" do
      before { sign_in other_user }

      it "redirects to league" do
        get fill_results_tournament_path(active_tournament)
        expect(response).to redirect_to(league_path(active_tournament.league))
      end
    end

    context "unauthenticated" do
      it "redirects to sign in" do
        get fill_results_tournament_path(active_tournament)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "PATCH /tournaments/:id/complete" do
    let(:points_rules) { [ { "from" => 1, "to" => 1, "points" => 10 }, { "from" => 2, "to" => 2, "points" => 5 } ] }
    let(:tournament) { create(:tournament, :active, league: league, placement_points: points_rules) }
    let(:lu1) { create(:league_user, league: league) }
    let(:lu2) { create(:league_user, league: league) }
    let!(:pair) { create(:pair, tournament: tournament, player1: lu1, player2: lu2) }

    context "as owner" do
      before { sign_in owner }

      it "completes the tournament and updates scores" do
        patch complete_tournament_path(tournament), params: { placements: { pair.id.to_s => 1 } }
        expect(response).to redirect_to(tournament_path(tournament))
        expect(tournament.reload.status).to eq("completed")
        expect(lu1.reload.score).to eq(10)
        expect(lu2.reload.score).to eq(10)
      end

      it "assigns placement to the pair" do
        patch complete_tournament_path(tournament), params: { placements: { pair.id.to_s => 2 } }
        expect(pair.reload.placement).to eq(2)
        expect(lu1.reload.score).to eq(5)
      end

      it "redirects to tournament when not active" do
        patch complete_tournament_path(draft_tournament)
        expect(response).to redirect_to(tournament_path(draft_tournament))
        expect(draft_tournament.reload.status).to eq("draft")
      end
    end

    context "as non-owner" do
      before { sign_in other_user }

      it "redirects to league without completing" do
        patch complete_tournament_path(tournament), params: { placements: { pair.id.to_s => 1 } }
        expect(response).to redirect_to(league_path(tournament.league))
        expect(tournament.reload.status).to eq("active")
      end
    end

    context "unauthenticated" do
      it "redirects to sign in" do
        patch complete_tournament_path(tournament)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "POST /tournaments/:id/cancel" do
    let(:registration_tournament) { create(:tournament, :registration, league: league) }
    let(:lu1) { create(:league_user, league: league) }
    let(:lu2) { create(:league_user, league: league) }
    let!(:pair) { create(:pair, tournament: registration_tournament, player1: lu1, player2: lu2) }

    context "as owner" do
      before { sign_in owner }

      it "cancels the tournament and redirects" do
        post cancel_tournament_path(registration_tournament)
        expect(response).to redirect_to(tournament_path(registration_tournament))
        expect(registration_tournament.reload.status).to eq("cancelled")
      end

      it "notifies registered players" do
        expect {
          post cancel_tournament_path(registration_tournament)
        }.to change(Notification, :count).by(2)

        notification = Notification.last
        expect(notification.notification_type).to eq("tournament_cancelled")
      end

      it "does not cancel a non-registration tournament" do
        post cancel_tournament_path(draft_tournament)
        expect(response).to redirect_to(tournament_path(draft_tournament))
        expect(draft_tournament.reload.status).to eq("draft")
      end
    end

    context "as non-owner" do
      before { sign_in other_user }

      it "does not cancel tournament and redirects to league" do
        post cancel_tournament_path(registration_tournament)
        expect(response).to redirect_to(league_path(registration_tournament.league))
        expect(registration_tournament.reload.status).to eq("registration")
      end
    end

    context "unauthenticated" do
      it "redirects to sign in" do
        post cancel_tournament_path(registration_tournament)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "GET /tournaments/:id/edit" do
    context "as owner" do
      before { sign_in owner }

      it "returns 200 for draft tournament" do
        get edit_tournament_path(draft_tournament)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Редактировать турнир")
        expect(response.body).to include(draft_tournament.name)
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
        expect(response.body).to include("Редактировать турнир")
      end

      it "persists ranking_method for round_robin tournament" do
        rr = create(:tournament, league: league, type: :round_robin)
        patch tournament_path(rr), params: { tournament: { ranking_method: "by_wins" } }
        expect(rr.reload.ranking_method).to eq("by_wins")
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

  describe "GET /tournaments/:id/fill_results - round_robin ranking_method" do
    # Scenario: X has 2 wins but lower net score, Y has 1 win but higher net score
    #   Match Y vs Z: Y wins 20-1  → Y: wins=1, net=+15  (wins_score=20, losses_score=5)
    #   Match X vs Z: X wins  6-5  → X: wins=1, net=+6 so far
    #   Match X vs Y: X wins  6-5  → X: wins=2, net=+12  (wins_score=12, losses_score=0)
    #                                  Z: wins=0, net=-6
    # score_delta ranking: Y(15) > X(12) > Z(-6)
    # by_wins    ranking:  X(2W) > Y(1W) > Z(0W)
    let(:user_x) { create(:user, first_name: "PairX", last_name: "Alpha") }
    let(:user_y) { create(:user, first_name: "PairY", last_name: "Beta") }
    let(:user_z) { create(:user, first_name: "PairZ", last_name: "Gamma") }
    let(:lu_x)   { create(:league_user, league: league, user: user_x) }
    let(:lu_y)   { create(:league_user, league: league, user: user_y) }
    let(:lu_z)   { create(:league_user, league: league, user: user_z) }
    let(:rr_tournament) do
      create(:tournament, :active, league: league, type: :round_robin,
             max_participants: 6, ranking_method: ranking_method)
    end

    before do
      sign_in owner

      [lu_x, lu_y, lu_z].each do |lu|
        create(:pair, tournament: rr_tournament, player1: lu, player2: create(:league_user, league: league))
      end

      Tournaments::Matches::AutoAssignPairsService.new(rr_tournament).call

      rr_tournament.pairs.reload
      pair_x = rr_tournament.pairs.find { |p| p.player1_id == lu_x.id }
      pair_y = rr_tournament.pairs.find { |p| p.player1_id == lu_y.id }
      pair_z = rr_tournament.pairs.find { |p| p.player1_id == lu_z.id }

      all_matches = Match.where(tournament_id: rr_tournament.id).to_a

      [
        [ pair_y, pair_z, pair_y, 20, 1 ],
        [ pair_x, pair_z, pair_x, 6, 5 ],
        [ pair_x, pair_y, pair_x, 6, 5 ]
      ].each do |pa, pb, winner, score_a, score_b|
        m = all_matches.find { |m| [ m.pair1_id, m.pair2_id ].to_set == Set.new([ pa.id, pb.id ]) }
        pair1_score = m.pair1_id == pa.id ? score_a : score_b
        pair2_score = m.pair1_id == pa.id ? score_b : score_a
        m.update!(status: :completed, winner_id: winner.id,
                  pair1_score: pair1_score, pair2_score: pair2_score)
      end
    end

    context "with score_delta ranking_method" do
      let(:ranking_method) { :score_delta }

      it "places Y (highest score delta) before X (more wins)" do
        get fill_results_tournament_path(rr_tournament)
        expect(response).to have_http_status(:ok)
        expect(response.body.index("PairY")).to be < response.body.index("PairX")
      end
    end

    context "with by_wins ranking_method" do
      let(:ranking_method) { :by_wins }

      it "places X (most wins) before Y (higher score delta)" do
        get fill_results_tournament_path(rr_tournament)
        expect(response).to have_http_status(:ok)
        expect(response.body.index("PairX")).to be < response.body.index("PairY")
      end
    end
  end
end
