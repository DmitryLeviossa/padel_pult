module ApplicationHelper
  def tournament_date_range(tournament)
    s = tournament.start_date
    e = tournament.end_date

    if s.to_date == e.to_date
      "#{l(s, format: :long)} - #{e.strftime('%H:%M')}"
    elsif s.year == e.year && s.month == e.month
      "#{s.strftime('%-d')}-#{l(e.to_date, format: :long)}"
    else
      "#{l(s, format: :long)} — #{l(e, format: :long)}"
    end
  end
end
