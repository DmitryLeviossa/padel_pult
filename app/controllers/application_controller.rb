class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  before_action :authenticate_user!
  before_action :load_pending_invitations, if: :user_signed_in?
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def load_pending_invitations
    @unread_notifications = current_user.notifications.unread.recent
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:first_name, :last_name, :gender, :photo])
    devise_parameter_sanitizer.permit(:account_update, keys: [:first_name, :last_name, :gender, :photo])
  end
end
