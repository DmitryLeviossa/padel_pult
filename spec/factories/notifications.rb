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
#  index_notifications_on_user_id              (user_id)
#  index_notifications_on_user_id_and_read_at  (user_id,read_at)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
FactoryBot.define do
  factory :notification do
    association :user
    notification_type { :tournament_added }
    message { "Someone added you to a tournament" }
    url { "/tournaments/1" }
    read_at { nil }

    trait :read do
      read_at { Time.current }
    end
  end
end
