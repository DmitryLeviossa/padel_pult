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
#  index_league_users_on_league_id              (league_id)
#  index_league_users_on_user_id                (user_id)
#  index_league_users_on_user_id_and_league_id  (user_id,league_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (league_id => leagues.id)
#  fk_rails_...  (user_id => users.id)
#
class LeagueUser < ApplicationRecord
  belongs_to :league
  belongs_to :user

  validates :user_id, uniqueness: { scope: :league_id }

  delegate :full_name, to: :user

  def self.ransackable_attributes(_auth_object = nil)
    %w[score]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[user]
  end
end
