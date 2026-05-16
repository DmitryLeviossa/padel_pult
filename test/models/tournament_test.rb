# == Schema Information
#
# Table name: tournaments
#
#  id               :bigint           not null, primary key
#  description      :text
#  end_date         :date             not null
#  location         :string
#  max_participants :integer          default(16), not null
#  name             :string           not null
#  placement_points :jsonb            not null
#  start_date       :date             not null
#  status           :string           default("draft"), not null
#  type             :string           default("olimpic"), not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  league_id        :bigint           not null
#
# Indexes
#
#  index_tournaments_on_league_id  (league_id)
#
# Foreign Keys
#
#  fk_rails_...  (league_id => leagues.id)
#
require "test_helper"

class TournamentTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
