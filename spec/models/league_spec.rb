# == Schema Information
#
# Table name: leagues
#
#  id                :bigint           not null, primary key
#  description       :text
#  name              :string           not null
#  tournaments_quota :integer          default(5), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  owner_id          :bigint           not null
#
# Indexes
#
#  index_leagues_on_owner_id  (owner_id)
#
# Foreign Keys
#
#  fk_rails_...  (owner_id => users.id)
#
require "rails_helper"

RSpec.describe League, type: :model do
  describe "callbacks" do
    it "adds the owner as a league member on create" do
      league = create(:league)
      expect(league.users).to include(league.owner)
    end
  end
end
