require "rails_helper"

RSpec.describe "Brackets", type: :request do
  let(:owner) { create(:user) }
  let(:other_user) { create(:user) }
  let(:league) { create(:league, owner: owner) }
  let(:tournament) { create(:tournament, league: league) }

  describe "GET /tournaments/:tournament_id/brackets/new" do
    context "as owner" do
      before { sign_in owner }

      it "returns 200" do
        get new_tournament_bracket_path(tournament)
        expect(response).to have_http_status(:ok)
      end
    end

    context "as non-owner" do
      before { sign_in other_user }

      it "redirects to tournament" do
        get new_tournament_bracket_path(tournament)
        expect(response).to redirect_to(tournament_path(tournament))
      end
    end

    context "unauthenticated" do
      it "redirects to sign in" do
        get new_tournament_bracket_path(tournament)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "POST /tournaments/:tournament_id/brackets" do
    let(:valid_params) { { bracket: { name: "Основная сетка", pairs_count: 8 } } }
    let(:invalid_params) { { bracket: { name: "", pairs_count: 1 } } }

    context "as owner" do
      before { sign_in owner }

      it "creates a bracket with matches and redirects to tournament" do
        expect { post tournament_brackets_path(tournament), params: valid_params }
          .to change { tournament.brackets.where("group_number > 0").count }.by(1)
        bracket = tournament.brackets.where("group_number > 0").last
        expect(bracket.name).to eq("Основная сетка")
        expect(bracket.pairs_count).to eq(8)
        expect(bracket.matches.count).to be > 0
        expect(response).to redirect_to(tournament_path(tournament, anchor: "bracket-#{bracket.id}"))
      end

      it "generates correct number of matches for 8 pairs" do
        post tournament_brackets_path(tournament), params: valid_params
        bracket = tournament.brackets.where("group_number > 0").last
        # 8 pairs = 4 + 2 + 1 (final) + 1 (3rd place) = 8 matches
        expect(bracket.matches.count).to eq(8)
      end

      it "supports creating multiple brackets" do
        post tournament_brackets_path(tournament), params: valid_params
        post tournament_brackets_path(tournament), params: { bracket: { name: "Вторая сетка", pairs_count: 4 } }
        expect(tournament.brackets.where("group_number > 0").count).to eq(2)
      end

      it "re-renders new with errors on invalid params" do
        post tournament_brackets_path(tournament), params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "as non-owner" do
      before do
        sign_in other_user
        tournament # ensure tournament exists before the expect block
      end

      it "does not create a bracket" do
        expect { post tournament_brackets_path(tournament), params: valid_params }
          .not_to change { tournament.brackets.where("group_number > 0").count }
        expect(response).to redirect_to(tournament_path(tournament))
      end
    end

    context "unauthenticated" do
      it "redirects to sign in" do
        post tournament_brackets_path(tournament), params: valid_params
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
