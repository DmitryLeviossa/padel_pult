class TournamentParticipantsController < ApplicationController
  before_action :set_tournament
  before_action :authorize_registration_open!, only: :create
  before_action :set_participant, only: :destroy
  before_action :authorize_league_owner!, only: :destroy

  def create
    if owner_adding?
      league_user = @tournament.league.league_users.find(params.dig(:tournament_participant, :league_user_id))
      @participant = @tournament.tournament_participants.build(league_user: league_user)
    else
      @participant = @tournament.tournament_participants.build(league_user: current_league_user)
    end

    if @participant.save
      notify_registered unless owner_adding?
      redirect_to tournament_path(@tournament), notice: "Вы зарегистрированы на турнир."
    else
      redirect_to tournament_path(@tournament), alert: @participant.errors.full_messages.to_sentence
    end
  end

  def destroy
    @participant.destroy
    redirect_to tournament_path(@tournament), notice: "Участник удалён."
  end

  private

  def set_tournament
    @tournament = Tournament.find(params[:tournament_id])
  end

  def set_participant
    @participant = @tournament.tournament_participants.find(params[:id])
  end

  def current_league_user
    @current_league_user ||= @tournament.league.league_users.find_by!(user: current_user)
  rescue ActiveRecord::RecordNotFound
    nil
  end

  def owner_adding?
    params.dig(:tournament_participant, :league_user_id).present?
  end

  def authorize_registration_open!
    unless @tournament.registration?
      redirect_to tournament_path(@tournament), alert: "Регистрация на этот турнир закрыта."
    end
  end

  def authorize_league_owner!
    unless @tournament.league.owner == current_user && @tournament.registration?
      redirect_to tournament_path(@tournament), alert: "Удаление участников недоступно."
    end
  end

  def notify_registered
    league_user = current_league_user
    return unless league_user

    Notification.create!(
      user: league_user.user,
      notification_type: :tournament_added,
      message: "Вы зарегистрированы на турнир «#{@tournament.name}» в лиге «#{@tournament.league.name}»",
      url: tournament_path(@tournament)
    )
  end
end
