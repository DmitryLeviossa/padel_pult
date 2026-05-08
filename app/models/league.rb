# == Schema Information
#
# Table name: leagues
#
#  id          :bigint           not null, primary key
#  description :text
#  name        :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  owner_id    :bigint           not null
#
# Indexes
#
#  index_leagues_on_owner_id  (owner_id)
#
# Foreign Keys
#
#  fk_rails_...  (owner_id => users.id)
#
class League < ApplicationRecord
  belongs_to :owner, class_name: "User"

  has_many :tournaments
  has_many :league_users
  has_many :users, through: :league_users

  has_one_attached :logo
end
