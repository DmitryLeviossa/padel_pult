require "rails_helper"

RSpec.describe Notification, type: :model do
  let(:user) { create(:user) }

  describe "scopes" do
    describe ".unread" do
      it "includes notifications without read_at" do
        unread = create(:notification, user: user)
        expect(Notification.unread).to include(unread)
      end

      it "excludes notifications with read_at set" do
        read = create(:notification, :read, user: user)
        expect(Notification.unread).not_to include(read)
      end
    end

    describe ".recent" do
      it "orders by created_at descending" do
        older = create(:notification, user: user, created_at: 2.hours.ago)
        newer = create(:notification, user: user, created_at: 1.hour.ago)
        expect(Notification.recent.to_a).to eq([ newer, older ])
      end
    end
  end

  describe "#mark_as_read!" do
    it "sets read_at to current time" do
      notification = create(:notification, user: user)
      expect { notification.mark_as_read! }.to change { notification.read_at }.from(nil)
    end

    it "is idempotent when already read" do
      notification = create(:notification, :read, user: user)
      original_time = notification.read_at
      notification.mark_as_read!
      expect(notification.read_at).to be_within(1.second).of(original_time)
    end
  end
end
