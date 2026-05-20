# == Schema Information
#
# Table name: match_sets
#
#  id          :bigint           not null, primary key
#  pair1_score :integer          not null
#  pair2_score :integer          not null
#  set_number  :integer          not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  match_id    :bigint           not null
#
# Indexes
#
#  index_match_sets_on_match_id                 (match_id)
#  index_match_sets_on_match_id_and_set_number  (match_id,set_number) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (match_id => matches.id)
#
class MatchSet < ApplicationRecord
  belongs_to :match

  validates :set_number, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :pair1_score, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :pair2_score, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  default_scope { order(:set_number) }
end
