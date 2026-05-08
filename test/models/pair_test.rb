# == Schema Information
#
# Table name: pairs
#
#  id            :bigint           not null, primary key
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
require "test_helper"

class PairTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
