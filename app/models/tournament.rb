class Tournament < ApplicationRecord
  belongs_to :league
  has_many :pairs, dependent: :destroy
end
