require "rails_helper"

RSpec.describe "Pairs", type: :request do
  let(:owner) { create(:user) }
  let(:member1) { create(:user) }
  let(:member2) { create(:user) }
  let(:outsider) { create(:user) }
  let(:league) { create(:league, owner: owner) }
  let(:league_user1) { create(:league_user, league: league, user: member1) }
  let(:league_user2) { create(:league_user, league: league, user: member2) }
  let(:registration_tournament) { create(:tournament, league: league, status: :registration) }
  let(:draft_tournament) { create(:tournament, league: league) }

  before do
    league_user1
    league_user2
  end

  describe "POST /tournaments/:tournament_id/pairs" do
    context "as league member" do
      before { sign_in member1 }

      it "creates a pair and redirects to tournament" do
        expect {
          post tournament_pairs_path(registration_tournament),
               params: { pair: { player2_id: league_user2.id } }
        }.to change(Pair, :count).by(1)

        expect(response).to redirect_to(tournament_path(registration_tournament))
      end

      it "sets player1 to the current user's league_user" do
        post tournament_pairs_path(registration_tournament),
             params: { pair: { player2_id: league_user2.id } }

        pair = Pair.last
        expect(pair.player1).to eq(league_user1)
        expect(pair.player2).to eq(league_user2)
      end

      it "does not create pair when already registered" do
        create(:pair, tournament: registration_tournament, player1: league_user1, player2: league_user2)

        expect {
          post tournament_pairs_path(registration_tournament),
               params: { pair: { player2_id: league_user2.id } }
        }.not_to change(Pair, :count)
      end

      it "does not create pair when tournament is not in registration" do
        expect {
          post tournament_pairs_path(draft_tournament),
               params: { pair: { player2_id: league_user2.id } }
        }.not_to change(Pair, :count)

        expect(response).to redirect_to(tournament_path(draft_tournament))
      end
    end

    context "as non-member" do
      before { sign_in outsider }

      it "does not create a pair and redirects" do
        expect {
          post tournament_pairs_path(registration_tournament),
               params: { pair: { player2_id: league_user2.id } }
        }.not_to change(Pair, :count)

        expect(response).to redirect_to(tournament_path(registration_tournament))
      end
    end
  end

  describe "PATCH /tournaments/:tournament_id/pairs/:id (player change)" do
    let(:member3) { create(:user) }
    let(:league_user3) { create(:league_user, league: league, user: member3, score: 42) }
    let(:pair) { create(:pair, tournament: registration_tournament, player1: league_user1, player2: league_user2) }

    before { league_user3 }

    context "as league owner" do
      before { sign_in owner }

      it "changes player1 and updates player1_score" do
        patch tournament_pair_path(registration_tournament, pair),
              params: { pair: { player1_id: league_user3.id } }

        pair.reload
        expect(pair.player1).to eq(league_user3)
        expect(pair.player1_score).to eq(league_user3.score)
        expect(response).to redirect_to(tournament_path(registration_tournament))
      end

      it "changes player2 and updates player2_score" do
        patch tournament_pair_path(registration_tournament, pair),
              params: { pair: { player2_id: league_user3.id } }

        pair.reload
        expect(pair.player2).to eq(league_user3)
        expect(pair.player2_score).to eq(league_user3.score)
        expect(response).to redirect_to(tournament_path(registration_tournament))
      end

      it "does not change player when tournament is not in registration" do
        active_tournament = create(:tournament, league: league, status: :active)
        active_pair = create(:pair, tournament: active_tournament, player1: league_user1, player2: league_user2)

        patch tournament_pair_path(active_tournament, active_pair),
              params: { pair: { player1_id: league_user3.id } }

        active_pair.reload
        expect(active_pair.player1).to eq(league_user1)
        expect(response).to redirect_to(tournament_path(active_tournament))
      end

      it "does not change player to one already in another pair" do
        other_pair = create(:pair, tournament: registration_tournament, player1: league_user3, player2: create(:league_user, league: league))

        patch tournament_pair_path(registration_tournament, pair),
              params: { pair: { player1_id: other_pair.player1_id } }

        pair.reload
        expect(pair.player1).to eq(league_user1)
      end
    end

    context "as non-owner" do
      before { sign_in member1 }

      it "does not change player and redirects" do
        patch tournament_pair_path(registration_tournament, pair),
              params: { pair: { player1_id: league_user3.id } }

        pair.reload
        expect(pair.player1).to eq(league_user1)
        expect(response).to redirect_to(tournament_path(registration_tournament))
      end
    end
  end

  describe "DELETE /tournaments/:tournament_id/pairs/:id" do
    let(:pair) { create(:pair, tournament: registration_tournament, player1: league_user1, player2: league_user2) }

    context "as league owner" do
      before { sign_in owner }

      it "deletes the pair and redirects to tournament" do
        pair

        expect {
          delete tournament_pair_path(registration_tournament, pair)
        }.to change(Pair, :count).by(-1)

        expect(response).to redirect_to(tournament_path(registration_tournament))
      end

      it "does not delete pair when tournament is not in registration" do
        draft_pair = create(:pair, tournament: draft_tournament, player1: league_user1, player2: league_user2)

        expect {
          delete tournament_pair_path(draft_tournament, draft_pair)
        }.not_to change(Pair, :count)

        expect(response).to redirect_to(tournament_path(draft_tournament))
      end
    end

    context "as league member (non-owner)" do
      before { sign_in member1 }

      it "does not delete the pair and redirects" do
        pair

        expect {
          delete tournament_pair_path(registration_tournament, pair)
        }.not_to change(Pair, :count)

        expect(response).to redirect_to(tournament_path(registration_tournament))
      end
    end

    context "as outsider" do
      before { sign_in outsider }

      it "does not delete the pair and redirects" do
        pair

        expect {
          delete tournament_pair_path(registration_tournament, pair)
        }.not_to change(Pair, :count)

        expect(response).to redirect_to(tournament_path(registration_tournament))
      end
    end
  end
end
