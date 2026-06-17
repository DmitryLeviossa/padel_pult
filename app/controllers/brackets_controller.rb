class BracketsController < ApplicationController
  before_action :set_tournament
  before_action :authorize_owner!
  before_action :set_bracket, only: [:destroy]

  def new
    type = params[:bracket_type] == "group_stage" ? :group_stage : :bracket
    @bracket = Bracket.new(bracket_type: type)
    @available_pairs = @tournament.pairs.includes({ player1: :user }, { player2: :user }) if type == :group_stage
  end

  def create
    service = if bracket_params[:bracket_type] == "group_stage"
      Brackets::CreateGroupService.new(@tournament, bracket_params)
    else
      Brackets::CreateService.new(@tournament, bracket_params)
    end

    @bracket = service.call

    if @bracket.persisted?
      notice = @bracket.group_stage? ? "Группа создана." : "Сетка создана."
      redirect_to tournament_path(@tournament, anchor: "bracket-#{@bracket.id}"), notice: notice
    else
      @available_pairs = @tournament.pairs.includes({ player1: :user }, { player2: :user }) if @bracket.group_stage?
    render :new, status: :unprocessable_entity
    end
  end

  def destroy
    notice = @bracket.group_stage? ? "Группа удалена." : "Сетка удалена."
    @bracket.destroy!
    redirect_to tournament_path(@tournament), notice: notice
  end

  private

  def set_tournament
    @tournament = Tournament.find(params[:tournament_id])
  end

  def set_bracket
    @bracket = @tournament.brackets.find(params[:id])
  end

  def authorize_owner!
    redirect_to tournament_path(@tournament), alert: "Нет доступа." unless @tournament.league.owner == current_user
  end

  def bracket_params
    params.require(:bracket).permit(:name, :pairs_count, :bracket_type, pair_ids: [])
  end
end
