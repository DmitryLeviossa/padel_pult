# == Schema Information
#
# Table name: pairs
#
#  id            :bigint           not null, primary key
#  placement     :integer
#  player1_score :integer          default(0), not null
#  player2_score :integer          default(0), not null
#  seeded        :boolean          default(FALSE), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  player1_id    :bigint           not null
#  player2_id    :bigint           not null
#  tournament_id :bigint           not null
#
# Indexes
#
#  index_pairs_on_player1_id     (player1_id)
#  index_pairs_on_player2_id     (player2_id)
#  index_pairs_on_tournament_id  (tournament_id)
#
# Foreign Keys
#
#  fk_rails_...  (player1_id => league_users.id)
#  fk_rails_...  (player2_id => league_users.id)
#  fk_rails_...  (tournament_id => tournaments.id)
#
require "rails_helper"

RSpec.describe Pair, type: :model do
  describe "score snapshot on create" do
    it "captures player scores at registration time" do
      player1 = create(:league_user, score: 10)
      player2 = create(:league_user, score: 20)
      pair = create(:pair, player1: player1, player2: player2)

      expect(pair.player1_score).to eq(10)
      expect(pair.player2_score).to eq(20)
    end

    it "does not update stored scores when player scores change later" do
      player1 = create(:league_user, score: 5)
      player2 = create(:league_user, score: 15)
      pair = create(:pair, player1: player1, player2: player2)

      player1.update!(score: 100)
      player2.update!(score: 200)

      expect(pair.reload.player1_score).to eq(5)
      expect(pair.reload.player2_score).to eq(15)
    end
  end

  describe "#score" do
    it "returns sum of stored player scores" do
      player1 = create(:league_user, score: 30)
      player2 = create(:league_user, score: 40)
      pair = create(:pair, player1: player1, player2: player2)
      expect(pair.score).to eq(70)
    end
  end
end
