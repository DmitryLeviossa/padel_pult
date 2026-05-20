module ApplicationHelper
  RU_MONTHS = %w[января февраля марта апреля мая июня июля августа сентября октября ноября декабря].freeze

  def ru_date(date)
    "#{date.day} #{RU_MONTHS[date.month - 1]} #{date.year} г."
  end

  def ru_datetime(datetime)
    "#{datetime.day} #{RU_MONTHS[datetime.month - 1]} #{datetime.year} г., #{datetime.strftime('%H:%M')}"
  end

  def tournament_date_range(tournament)
    s = tournament.start_date
    e = tournament.end_date

    if s.to_date == e.to_date
      "#{ru_datetime(s)} - #{e.strftime('%H:%M')}"
    elsif s.year == e.year && s.month == e.month
      "#{s.strftime('%-d')}-#{ru_date(e.to_date)}"
    else
      "#{ru_datetime(s)} — #{ru_datetime(e)}"
    end
  end
end
