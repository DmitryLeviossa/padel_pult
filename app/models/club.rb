# == Schema Information
#
# Table name: clubs
#
#  id         :bigint           not null, primary key
#  address    :string
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Club < ApplicationRecord
  has_many :tournaments, dependent: :nullify
  has_one_attached :logo

  validates :name, presence: true

  def self.ransackable_attributes(_auth_object = nil)
    %w[name address]
  end
end
