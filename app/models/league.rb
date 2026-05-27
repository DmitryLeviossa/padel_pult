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
#  chat_id           :string
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
class League < ApplicationRecord
  belongs_to :owner, class_name: "User"

  has_many :tournaments, dependent: :destroy
  has_many :league_users, dependent: :destroy
  has_many :users, through: :league_users
  has_many :league_invitations

  has_one_attached :logo

  after_create :add_owner_as_member

  private

  def add_owner_as_member
    league_users.create!(user: owner)
  end

  def self.ransackable_attributes(auth_object = nil)
    %w[name description created_at]
  end
end
