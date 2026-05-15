module TournamentsHelper
  def sort_link(tournament, column, label, current_sort, current_direction)
    is_active = current_sort == column
    next_direction = is_active && current_direction == "asc" ? "desc" : "asc"
    arrow = is_active ? (current_direction == "asc" ? " ↑" : " ↓") : ""
    link_to "#{label}#{arrow}",
            tournament_path(tournament, sort: column, direction: next_direction),
            class: "text-decoration-none text-body#{' fw-semibold' if is_active}"
  end
end
