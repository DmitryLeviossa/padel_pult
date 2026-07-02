require "rails_helper"

RSpec.describe Bracket, type: :model do
  let(:tournament) { create(:tournament, groups_count: 2) }

  describe "enum bracket_type" do
    it "recognizes group_stage, bracket, loser_bracket" do
      expect(described_class.bracket_types.keys).to match_array(%w[group_stage bracket loser_bracket])
    end
  end

  describe "#manual?" do
    context "group_stage bracket" do
      it "is false when group_number <= groups_count" do
        b = tournament.brackets.build(bracket_type: :group_stage, group_number: 1)
        expect(b.manual?).to be false
      end

      it "is true when group_number > groups_count" do
        b = tournament.brackets.build(bracket_type: :group_stage, group_number: 3)
        expect(b.manual?).to be true
      end
    end

    context "bracket type" do
      it "is false when group_number is 0" do
        b = tournament.brackets.build(bracket_type: :bracket, group_number: 0)
        expect(b.manual?).to be false
      end

      it "is true when group_number > 0" do
        b = tournament.brackets.build(bracket_type: :bracket, group_number: 1)
        expect(b.manual?).to be true
      end
    end

    context "loser_bracket type" do
      it "is always false" do
        b = tournament.brackets.build(bracket_type: :loser_bracket, group_number: 5)
        expect(b.manual?).to be false
      end
    end
  end

  describe "validations for manual brackets" do
    context "manual group_stage bracket (group_number > groups_count)" do
      it "requires name" do
        b = tournament.brackets.build(bracket_type: :group_stage, group_number: 3, pairs_count: 4)
        expect(b).not_to be_valid
        expect(b.errors[:name]).to be_present
      end

      it "requires pairs_count >= 2" do
        b = tournament.brackets.build(bracket_type: :group_stage, group_number: 3, name: "Group X", pairs_count: 1)
        expect(b).not_to be_valid
        expect(b.errors[:pairs_count]).to be_present
      end

      it "is valid with name and valid pairs_count" do
        b = tournament.brackets.build(bracket_type: :group_stage, group_number: 3, name: "Group X", pairs_count: 4)
        expect(b).to be_valid
      end
    end

    context "non-manual bracket" do
      it "is valid without name or pairs_count" do
        b = tournament.brackets.build(bracket_type: :bracket, group_number: 0)
        expect(b).to be_valid
      end
    end
  end
end
