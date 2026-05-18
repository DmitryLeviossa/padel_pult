class LeagueInvitationsController < ApplicationController
  before_action :set_invitation

  def update
    case params[:status]
    when "accepted"
      ActiveRecord::Base.transaction do
        @invitation.accepted!
        @invitation.league.league_users.create!(user: current_user)
      end
      redirect_to league_path(@invitation.league), notice: t(".accepted")
    when "dismissed"
      @invitation.dismissed!
      redirect_back fallback_location: root_path, notice: t(".dismissed")
    else
      redirect_back fallback_location: root_path
    end
  rescue ActiveRecord::RecordInvalid
    redirect_back fallback_location: root_path, alert: t(".failed")
  end

  private

  def set_invitation
    @invitation = current_user.received_league_invitations.pending.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: t(".not_found")
  end
end
