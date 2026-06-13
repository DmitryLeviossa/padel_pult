class Leagues::LeagueInvitationsController < ApplicationController
  before_action :set_league
  before_action :authorize_owner!

  def create
    user_ids = Array(params.dig(:league_invitation, :invited_user_ids)).reject(&:blank?)

    if user_ids.empty?
      return redirect_to league_path(@league, anchor: "league-users"),
        alert: "Выберите хотя бы одного игрока."
    end

    invited_count = 0
    user_ids.each do |user_id|
      user = User.find_by(id: user_id)
      next unless user
      next unless user.pending_invitation?

      @league.league_users.create(user: user)
      invited_count += 1
    end

    redirect_to league_path(@league, anchor: "league-users"),
      notice: "Приглашения отправлены: #{invited_count}"
  end

  private

  def set_league
    @league = League.find(params[:league_id])
  end

  def authorize_owner!
    redirect_to leagues_path, alert: "Нет доступа." unless @league.owner == current_user
  end
end
