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
FactoryBot.define do
  factory :bracket do
    association :tournament
    bracket_type { "bracket" }
    group_number { 0 }

    initialize_with do
      tournament.brackets.find_or_create_by!(
        bracket_type: bracket_type,
        group_number: group_number
      )
    end
  end
end
