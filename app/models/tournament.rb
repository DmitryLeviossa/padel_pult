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
class Tournament < ApplicationRecord
  self.inheritance_column = nil

  belongs_to :league
  has_many :pairs, dependent: :destroy

  validates :status, inclusion: { in: %w[draft active completed cancelled] }
end
