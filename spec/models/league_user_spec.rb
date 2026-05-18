# == Schema Information
#
# Table name: league_users
#
#  id         :bigint           not null, primary key
#  score      :integer          default(0), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  league_id  :bigint           not null
#  user_id    :bigint           not null
#
# Indexes
#
#  index_league_users_on_league_id  (league_id)
#  index_league_users_on_user_id    (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (league_id => leagues.id)
#  fk_rails_...  (user_id => users.id)
#
require "rails_helper"

RSpec.describe LeagueUser, type: :model do
end
