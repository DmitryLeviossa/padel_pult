class Tournament < ApplicationRecord
  self.inheritance_column = nil

  belongs_to :league
  has_many :pairs, dependent: :destroy
end
