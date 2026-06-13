class Leagues::LeagueTelegramSettingsController < ApplicationController
  before_action :set_league
  before_action :authorize_owner!

  def create
    @setting = @league.build_league_telegram_setting(setting_params)

    if @setting.save
      redirect_to league_path(@league, tab: "settings", anchor: "settings"), notice: "Настройки Telegram сохранены."
    else
      redirect_to league_path(@league, tab: "settings", anchor: "settings"), alert: "Не удалось сохранить настройки."
    end
  end

  def update
    @setting = @league.league_telegram_setting

    if @setting.update(setting_params)
      redirect_to league_path(@league, tab: "settings", anchor: "settings"), notice: "Настройки Telegram сохранены."
    else
      redirect_to league_path(@league, tab: "settings", anchor: "settings"), alert: "Не удалось сохранить настройки."
    end
  end

  def send_test
    @setting = @league.league_telegram_setting

    if @setting&.chat_id.present?
      response = TelegramBotService.send_message(chat_id: @setting.chat_id, text: "👋 ПАДЕЛ Пульт интегрирован в чат")
      if response&.is_a?(Net::HTTPSuccess)
        redirect_to league_path(@league, tab: "settings", anchor: "settings"), notice: "Тестовое сообщение отправлено."
      else
        redirect_to league_path(@league, tab: "settings", anchor: "settings"), alert: "Не удалось отправить сообщение. Проверьте ID чата и токен бота."
      end
    else
      redirect_to league_path(@league, tab: "settings", anchor: "settings"), alert: "Сначала укажите ID чата."
    end
  end

  private

  def set_league
    @league = League.find(params[:league_id])
  end

  def authorize_owner!
    redirect_to leagues_path, alert: "Нет доступа." unless @league.owner == current_user
  end

  def setting_params
    params.require(:league_telegram_setting).permit(
      :chat_id,
      :match_results_thread_id,
      :announces_thread_id
    )
  end
end
