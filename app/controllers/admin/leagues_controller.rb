class Admin::LeaguesController < ApplicationController
  before_action :require_admin!

  def index
    @leagues = League.includes(:owner).order(:name)
  end

  def update
    @league = League.find(params[:id])
    if @league.update(quota_params)
      head :no_content
    else
      head :unprocessable_entity
    end
  end

  private

  def require_admin!
    redirect_to root_path, alert: "Нет доступа." unless current_user&.id == 1
  end

  def quota_params
    params.require(:league).permit(:tournaments_quota)
  end
end
