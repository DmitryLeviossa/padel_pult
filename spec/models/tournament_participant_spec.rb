require "rails_helper"

RSpec.describe TournamentParticipant, type: :model do
  let(:league) { create(:league) }
  let(:tournament) { create(:tournament, league: league) }
  let(:league_user) { create(:league_user, league: league) }

  describe "uniqueness" do
    it "prevents registering the same league_user twice in the same tournament" do
      create(:tournament_participant, tournament: tournament, league_user: league_user)
      dup = build(:tournament_participant, tournament: tournament, league_user: league_user)
      expect(dup).not_to be_valid
      expect(dup.errors[:league_user_id]).to include("уже зарегистрирован на этот турнир")
    end

    it "allows the same league_user in different tournaments" do
      other_tournament = create(:tournament, league: league)
      create(:tournament_participant, tournament: tournament, league_user: league_user)
      tp = build(:tournament_participant, tournament: other_tournament, league_user: league_user)
      expect(tp).to be_valid
    end
  end

  describe "delegations" do
    it "delegates full_name to league_user" do
      tp = create(:tournament_participant, tournament: tournament, league_user: league_user)
      expect(tp.full_name).to eq(league_user.full_name)
    end
  end
end
