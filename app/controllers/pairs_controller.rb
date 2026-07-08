class PairsController < ApplicationController
  before_action :set_tournament
  before_action :authorize_league_member!, only: :create, unless: :owner_adding_pair?
  before_action :authorize_registration_open!, only: :create
  before_action :authorize_not_already_registered!, only: :create, unless: :owner_adding_pair?
  before_action :authorize_owner_for_pair_add!, only: :create, if: :owner_adding_pair?
  before_action :set_pair, only: [ :destroy, :update ]
  before_action :authorize_league_owner!, only: :destroy
  before_action :authorize_owner_for_set!, only: :update

  def create
    if owner_adding_pair?
      player1 = @tournament.league.league_users.find(params.dig(:pair, :player1_id))
      player2 = @tournament.league.league_users.find(params.dig(:pair, :player2_id))
      @pair = @tournament.pairs.build(player1: player1, player2: player2)
    else
      @pair = @tournament.pairs.build(player1: current_league_user, player2: partner)
    end

    if @pair.save
      notify_partner unless owner_adding_pair?
      redirect_to tournament_path(@tournament)
    else
      redirect_to tournament_path(@tournament)
    end
  end

  def update
    if params.dig(:pair, :photo).present?
      @pair.photo.attach(params.dig(:pair, :photo))
    elsif (player1_id = params.dig(:pair, :player1_id)).present?
      @pair.player1 = @tournament.league.league_users.find(player1_id)
      return redirect_to tournament_path(@tournament), alert: @pair.errors.full_messages.to_sentence unless @pair.save
    elsif (player2_id = params.dig(:pair, :player2_id)).present?
      @pair.player2 = @tournament.league.league_users.find(player2_id)
      return redirect_to tournament_path(@tournament), alert: @pair.errors.full_messages.to_sentence unless @pair.save
    elsif params[:pair]&.key?("player1_count_score")
      @pair.update!(player1_count_score: params.dig(:pair, :player1_count_score) == "1")
    elsif params[:pair]&.key?("player2_count_score")
      @pair.update!(player2_count_score: params.dig(:pair, :player2_count_score) == "1")
    else
      @pair.update!(seeded: params.dig(:pair, :seeded) == "1")
    end
    redirect_to tournament_path(@tournament)
  end

  def destroy
    @pair.destroy
    redirect_to tournament_path(@tournament), notice: "Пара успешно удалена."
  end

  private

  def set_tournament
    @tournament = Tournament.find(params[:tournament_id])
  end

  def set_pair
    @pair = @tournament.pairs.find(params[:id])
  end

  def current_league_user
    @current_league_user ||= @tournament.league.league_users.find_by!(user: current_user)
  end

  def partner
    @partner ||= @tournament.league.league_users.find(params.dig(:pair, :player2_id))
  end

  def authorize_league_member!
    @tournament.league.league_users.find_by!(user: current_user)
  rescue ActiveRecord::RecordNotFound
    redirect_to tournament_path(@tournament), alert: "Вы не являетесь участником этой лиги."
  end

  def authorize_registration_open!
    unless @tournament.registration?
      redirect_to tournament_path(@tournament), alert: "Регистрация на этот турнир закрыта."
    end
  end

  def authorize_not_already_registered!
    league_user = current_league_user
    already_in = @tournament.pairs.exists?(player1_id: league_user.id) ||
                 @tournament.pairs.exists?(player2_id: league_user.id)
    if already_in
      redirect_to tournament_path(@tournament), alert: "Вы уже зарегистрированы на этот турнир."
    end
  end

  def notify_partner
    partner_user = partner.user
    return if partner_user == current_user

    Notification.create!(
      user: partner_user,
      notification_type: :tournament_added,
      message: "#{current_user.full_name} добавил(а) вас в турнир «#{@tournament.name}» в лиге «#{@tournament.league.name}»",
      url: tournament_path(@tournament)
    )
  end

  def authorize_league_owner!
    unless @tournament.league.owner == current_user && @tournament.registration?
      redirect_to tournament_path(@tournament), alert: "Удаление пар недоступно."
    end
  end

  def owner_adding_pair?
    params.dig(:pair, :player1_id).present?
  end

  def authorize_owner_for_pair_add!
    unless @tournament.league.owner == current_user
      redirect_to tournament_path(@tournament), alert: "У вас нет прав для выполнения этого действия."
      return
    end
    unless @tournament.registration?
      redirect_to tournament_path(@tournament), alert: "Добавление пар доступно только в период регистрации."
    end
  end

  def authorize_owner_for_set!
    unless @tournament.league.owner == current_user
      redirect_to tournament_path(@tournament), alert: "У вас нет прав для выполнения этого действия."
    end
  end
end
