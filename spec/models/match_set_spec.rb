# == Schema Information
#
# Table name: match_sets
#
#  id          :bigint           not null, primary key
#  pair1_score :integer          not null
#  pair2_score :integer          not null
#  set_number  :integer          not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  match_id    :bigint           not null
#
# Indexes
#
#  index_match_sets_on_match_id                 (match_id)
#  index_match_sets_on_match_id_and_set_number  (match_id,set_number) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (match_id => matches.id)
#
require "rails_helper"

RSpec.describe MatchSet, type: :model do
  subject(:match_set) { build(:match_set) }

  it "is valid with valid attributes" do
    expect(match_set).to be_valid
  end

  it "is invalid without set_number" do
    match_set.set_number = nil
    expect(match_set).not_to be_valid
  end

  it "is invalid with set_number less than 1" do
    match_set.set_number = 0
    expect(match_set).not_to be_valid
  end

  it "is invalid without pair1_score" do
    match_set.pair1_score = nil
    expect(match_set).not_to be_valid
  end

  it "is invalid without pair2_score" do
    match_set.pair2_score = nil
    expect(match_set).not_to be_valid
  end

  it "is invalid with negative pair1_score" do
    match_set.pair1_score = -1
    expect(match_set).not_to be_valid
  end

  it "is invalid with negative pair2_score" do
    match_set.pair2_score = -1
    expect(match_set).not_to be_valid
  end
end
