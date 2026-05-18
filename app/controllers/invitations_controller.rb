class InvitationsController < ApplicationController
  skip_before_action :authenticate_user!
  before_action :find_pending_user!

  def show; end

  def update
    if @user.update(invitation_params.merge(invitation_token: nil))
      sign_in @user
      redirect_to root_path, notice: t(".success")
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def find_pending_user!
    @user = User.find_by(invitation_token: params[:token])
    redirect_to root_path, alert: t("invitations.invalid_token") unless @user
  end

  def invitation_params
    params.require(:user).permit(:email, :password, :password_confirmation, :photo)
  end
end
