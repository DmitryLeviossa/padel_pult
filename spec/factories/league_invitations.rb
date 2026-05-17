# == Schema Information
#
# Table name: league_invitations
#
#  id              :bigint           not null, primary key
#  status          :integer          default("pending"), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  invited_by_id   :bigint           not null
#  invited_user_id :bigint           not null
#  league_id       :bigint           not null
#
# Indexes
#
#  index_league_invitations_on_invited_by_id                  (invited_by_id)
#  index_league_invitations_on_invited_user_id                (invited_user_id)
#  index_league_invitations_on_league_id                      (league_id)
#  index_league_invitations_on_league_id_and_invited_user_id  (league_id,invited_user_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (invited_by_id => users.id)
#  fk_rails_...  (invited_user_id => users.id)
#  fk_rails_...  (league_id => leagues.id)
#
FactoryBot.define do
  factory :league_invitation do
    association :league
    association :invited_user, factory: :user
    association :invited_by, factory: :user
    status { :pending }
  end
end
