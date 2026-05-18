class NotificationsController < ApplicationController
  def visit
    notification = current_user.notifications.find(params[:id])
    notification.mark_as_read! unless notification.read_at?
    redirect_to notification.url.presence || root_path
  end

  def mark_all_read
    current_user.notifications.unread.update_all(read_at: Time.current)
    redirect_back fallback_location: root_path
  end
end
