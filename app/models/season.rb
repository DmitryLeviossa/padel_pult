# == Schema Information
#
# Table name: seasons
#
#  id          :bigint           not null, primary key
#  date_from   :date             not null
#  date_to     :date             not null
#  description :text
#  name        :string           default(""), not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  league_id   :bigint           not null
#
# Indexes
#
#  index_seasons_on_league_id  (league_id)
#
# Foreign Keys
#
#  fk_rails_...  (league_id => leagues.id)
#
class Season < ApplicationRecord
  belongs_to :league
  has_one_attached :logo

  validates :name, presence: true
  validates :date_from, presence: true
  validates :date_to, presence: true
  validate :date_to_not_before_date_from

  def status
    today = Date.today
    if date_from > today
      :upcoming
    elsif today <= date_to
      :active
    else
      :finished
    end
  end

  def upcoming? = status == :upcoming
  def active?   = status == :active
  def finished? = status == :finished

  private

  def date_to_not_before_date_from
    return unless date_from && date_to
    errors.add(:date_to, "не может быть раньше даты начала") if date_to < date_from
  end
end
