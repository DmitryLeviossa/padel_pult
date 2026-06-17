# == Schema Information
#
# Table name: brackets
#
#  id            :bigint           not null, primary key
#  bracket_type  :string           not null
#  group_number  :integer          default(0), not null
#  name          :string
#  pairs_count   :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  tournament_id :bigint           not null
#
# Indexes
#
#  index_brackets_on_tournament_id  (tournament_id)
#  index_brackets_uniqueness        (tournament_id,bracket_type,group_number) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (tournament_id => tournaments.id)
#
class Bracket < ApplicationRecord
  belongs_to :tournament
  has_many :matches, dependent: :destroy

  enum :bracket_type, { group_stage: "group", bracket: "bracket", loser_bracket: "loser_bracket" }

  validates :name, presence: true, if: :manual?
  validates :pairs_count, presence: true,
                          numericality: { only_integer: true, greater_than_or_equal_to: 2, less_than_or_equal_to: 64 },
                          if: :manual?

  def manual?
    (bracket? || group_stage?) && group_number > 0
  end
end
