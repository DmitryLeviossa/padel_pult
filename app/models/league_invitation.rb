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
class LeagueInvitation < ApplicationRecord
  belongs_to :league
  belongs_to :invited_user, class_name: "User"
  belongs_to :invited_by, class_name: "User"

  enum :status, { pending: 0, accepted: 1, dismissed: 2 }

  validates :invited_user_id, uniqueness: { scope: :league_id }
  validate :invited_user_not_already_member

  private

  def invited_user_not_already_member
    return unless league && invited_user
    errors.add(:invited_user, "уже является участником этой лиги") if league.users.include?(invited_user)
  end
end
