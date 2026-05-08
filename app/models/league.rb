class League < ApplicationRecord
  belongs_to :owner, class_name: "User"

  has_many :tournaments
  has_many :league_users
  has_many :users, through: :league_users
end
