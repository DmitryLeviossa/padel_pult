require "rails_helper"

RSpec.describe "Notifications", type: :request do
  let(:user) { create(:user) }

  before { sign_in user }

  describe "GET /notifications/:id/visit" do
    let!(:notification) { create(:notification, user: user, url: "/tournaments/1") }

    it "marks the notification as read" do
      get visit_notification_path(notification)
      expect(notification.reload.read_at).not_to be_nil
    end

    it "redirects to the notification url" do
      get visit_notification_path(notification)
      expect(response).to redirect_to("/tournaments/1")
    end

    it "does not re-set read_at if already read" do
      notification.mark_as_read!
      original_time = notification.read_at
      get visit_notification_path(notification)
      expect(notification.reload.read_at).to be_within(1.second).of(original_time)
    end

    it "returns 404 for another user's notification" do
      other_notification = create(:notification)
      get visit_notification_path(other_notification)
      expect(response.status).to eq(404)
    end
  end

  describe "PATCH /notifications/mark_all_read" do
    let!(:notifications) { create_list(:notification, 3, user: user) }

    it "marks all unread notifications as read" do
      patch mark_all_read_notifications_path
      expect(user.notifications.unread).to be_empty
    end

    it "does not affect other users' notifications" do
      other_notification = create(:notification)
      patch mark_all_read_notifications_path
      expect(other_notification.reload.read_at).to be_nil
    end

    it "redirects back to root" do
      patch mark_all_read_notifications_path
      expect(response).to redirect_to(root_path)
    end
  end
end
