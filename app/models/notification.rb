# == Schema Information
#
# Table name: notifications
#
#  id                :bigint           not null, primary key
#  message           :string           not null
#  notification_type :string           not null
#  read_at           :datetime
#  url               :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  user_id           :bigint           not null
#
# Indexes
#
#  index_notifications_on_user_id          (user_id)
#  index_notifications_on_user_id_read_at  (user_id,read_at)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class Notification < ApplicationRecord
  belongs_to :user

  enum :notification_type, { tournament_added: "tournament_added", league_invitation: "league_invitation", tournament_registration_open: "tournament_registration_open" }

  scope :unread, -> { where(read_at: nil) }
  scope :recent, -> { order(created_at: :desc) }

  def mark_as_read!
    update!(read_at: Time.current)
  end
end
