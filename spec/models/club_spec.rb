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
require "rails_helper"

RSpec.describe Club, type: :model do
  describe "validations" do
    it "is valid with a name" do
      club = build(:club)
      expect(club).to be_valid
    end

    it "is invalid without a name" do
      club = build(:club, name: nil)
      expect(club).not_to be_valid
      expect(club.errors[:name]).to be_present
    end
  end

  describe ".ransackable_attributes" do
    it "returns name and address" do
      expect(described_class.ransackable_attributes).to match_array(%w[name address])
    end
  end
end
