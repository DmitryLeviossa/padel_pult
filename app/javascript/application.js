// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import "bootstrap"
function initTomSelects() {
  document.querySelectorAll("select.form-select:not(.ts-hidden-accessible)").forEach(el => {
    const isAutoSubmit = !!el.closest("form[data-auto-submit]")
    const options = el.multiple
      ? { plugins: ["remove_button"] }
      : { allowEmptyOption: true }

    if (isAutoSubmit) {
      options.onChange = () => el.closest("form").requestSubmit()
    }

    new window.TomSelect(el, options)
  })
}

function initDateRangePicker() {
  const input = document.getElementById("date_range_picker")
  if (!input || !window.flatpickr) return

  const startHidden = document.getElementById("tournament_start_date")
  const endHidden   = document.getElementById("tournament_end_date")

  const defaultDates = []
  if (input.dataset.start) defaultDates.push(input.dataset.start)
  if (input.dataset.end)   defaultDates.push(input.dataset.end)

  window.flatpickr(input, {
    mode: "range",
    dateFormat: "Y-m-d",
    altInput: true,
    altFormat: "d.m.Y",
    defaultDate: defaultDates.length === 2 ? defaultDates : undefined,
    onChange(selectedDates) {
      startHidden.value = selectedDates[0] ? flatpickr.formatDate(selectedDates[0], "Y-m-d") : ""
      endHidden.value   = selectedDates[1] ? flatpickr.formatDate(selectedDates[1], "Y-m-d") : ""
    }
  })
}

function initAutoSubmitFilters() {
  document.querySelectorAll("form[data-auto-submit] input[type=search], form[data-auto-submit] input[type=text]").forEach(input => {
    let lastValue = input.value
    input.addEventListener("blur", () => {
      if (input.value !== lastValue) {
        lastValue = input.value
        input.form.requestSubmit()
      }
    })
    input.addEventListener("keydown", e => {
      if (e.key === "Enter") {
        e.preventDefault()
        lastValue = input.value
        input.form.requestSubmit()
      }
    })
  })
}

document.addEventListener("turbo:load", () => { initTomSelects(); initAutoSubmitFilters(); initDateRangePicker() })
document.addEventListener("turbo:render", () => { initTomSelects(); initAutoSubmitFilters(); initDateRangePicker() })
