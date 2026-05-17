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
      invited_count += 1 if invitation.save
    end

    redirect_to league_path(@league, anchor: "league-users"),
      notice: t(".success", count: invited_count)
  end

  private

  def set_league
    @league = League.find(params[:league_id])
  end

  def authorize_owner!
    redirect_to leagues_path, alert: t("leagues.show.not_authorized") unless @league.owner == current_user
  end
end
