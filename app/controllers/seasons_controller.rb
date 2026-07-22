class SeasonsController < ApplicationController
  before_action :set_league
  before_action :set_season, only: [:show, :edit, :update, :destroy, :results_pdf, :download_pdf, :send_pdf_to_telegram]
  before_action :authorize_owner!, only: [:new, :create, :edit, :update, :destroy, :send_pdf_to_telegram]
  skip_before_action :authenticate_user!, only: :results_pdf

  def show
    load_results
  end

  def results_pdf
    load_results
    render layout: "print"
  end

  def download_pdf
    pdf_path = SeasonResultsPdfService.new(@season).call
    send_data File.binread(pdf_path), filename: "#{@season.name.parameterize}-results.pdf", type: "application/pdf", disposition: "attachment"
  ensure
    FileUtils.rm_f(pdf_path) if pdf_path
  end

  def send_pdf_to_telegram
    tg = @league.league_telegram_setting
    unless tg&.chat_id.present?
      redirect_to league_season_path(@league, @season), alert: "Telegram не настроен для этой лиги."
      return
    end

    deliver_pdf_to_telegram(season_id: @season.id, season_name: @season.name, chat_id: tg.chat_id, thread_id: tg.announces_thread_id)

    redirect_to league_season_path(@league, @season), notice: "Отправка результатов в Telegram запущена."
  end

  def new
    @season = @league.seasons.new
  end

  def create
    @season = @league.seasons.new(season_params)
    if @season.save
      redirect_to league_season_path(@league, @season), notice: "Сезон создан."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @season.update(season_params)
      redirect_to league_season_path(@league, @season), notice: "Сезон обновлён."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @season.destroy
    redirect_to league_path(@league, anchor: "seasons"), notice: "Сезон удалён."
  end

  private

  def set_league
    @league = League.find(params[:league_id])
  end

  def set_season
    @season = @league.seasons.find(params[:id])
  end

  def authorize_owner!
    redirect_to league_path(@league), alert: "Нет доступа." unless @league.owner == current_user
  end

  def season_params
    params.require(:season).permit(:name, :date_from, :date_to, :description, :logo)
  end

  def load_results
    @tournaments = @league.tournaments
      .where(start_date: @season.date_from..@season.date_to)
      .order(start_date: :asc)

    tournaments = @tournaments.completed

    pairs = Pair.where(tournament: tournaments)
      .where.not(placement: nil)
      .includes(:tournament)

    points_by_user = Hash.new(0)
    pairs.each do |pair|
      pts = pair.tournament.points_for_place(pair.placement)
      next if pts.zero?
      points_by_user[pair.player1_id] += pts
      points_by_user[pair.player2_id] += pts
    end

    @rankings = LeagueUser.where(id: points_by_user.keys)
      .includes(:user)
      .sort_by { |lu| -points_by_user[lu.id] }
      .map { |lu| { league_user: lu, points: points_by_user[lu.id] } }
  end

  def deliver_pdf_to_telegram(season_id:, season_name:, chat_id:, thread_id:)
    Thread.new do
      ActiveRecord::Base.connection_pool.with_connection do
        pdf_path = SeasonResultsPdfService.new(Season.find(season_id)).call
        begin
          TelegramBotService.send_document(chat_id: chat_id, thread_id: thread_id, file_path: pdf_path, caption: "Результаты сезона «#{season_name}»")
        ensure
          FileUtils.rm_f(pdf_path)
        end
      end
    rescue => e
      Rails.logger.error "SeasonResultsPdfService failed for season #{season_id}: #{e.message}"
    end
  end
end
