class Leagues::LeagueInvitationsController < ApplicationController
  before_action :set_league
  before_action :authorize_owner!

  def create
    user_ids = Array(params.dig(:league_invitation, :invited_user_ids)).reject(&:blank?)

    if user_ids.empty?
      return redirect_to league_path(@league, anchor: "league-users"),
        alert: t(".no_users_selected")
    end

    invited_count = 0
    user_ids.each do |user_id|
      invitation = @league.league_invitations.build(
        invited_user_id: user_id,
        invited_by: current_user
      )
      if invitation.save
        invited_count += 1
        create_invitation_notification(invitation)
      end
    end

    redirect_to league_path(@league, anchor: "league-users"),
      notice: t(".success", count: invited_count)
  end

  private

  def set_league
    @league = League.find(params[:league_id])
  end

  def create_invitation_notification(invitation)
    Notification.create!(
      user: invitation.invited_user,
      notification_type: :league_invitation,
      message: t("leagues.league_invitations.notifications.league_invitation",
                 league: @league.name,
                 inviter: current_user.full_name),
      url: league_path(@league)
    )
  end

  def authorize_owner!
    redirect_to leagues_path, alert: t("leagues.show.not_authorized") unless @league.owner == current_user
  end
end
