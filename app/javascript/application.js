// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import "bootstrap"

Turbo.config.forms.confirm = (message) => {
  return new Promise((resolve) => {
    const modalEl = document.getElementById("turboConfirmModal")
    document.getElementById("turboConfirmModalBody").textContent = message
    const modal = bootstrap.Modal.getOrCreateInstance(modalEl)
    const confirmBtn = document.getElementById("turboConfirmModalConfirm")

    const onConfirm = () => {
      cleanup()
      resolve(true)
    }
    const onDismiss = () => {
      cleanup()
      resolve(false)
    }
    const cleanup = () => {
      confirmBtn.removeEventListener("click", onConfirm)
      modalEl.removeEventListener("hide.bs.modal", onDismiss)
      modal.hide()
    }

    confirmBtn.addEventListener("click", onConfirm)
    modalEl.addEventListener("hide.bs.modal", onDismiss, { once: true })
    modal.show()
  })
}
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

function initDateTimePickers() {
  const startInput  = document.getElementById("tournament_start_date_picker")
  const endInput    = document.getElementById("tournament_end_date_picker")
  if ((!startInput && !endInput) || !window.flatpickr) return

  const startHidden = document.getElementById("tournament_start_date")
  const endHidden   = document.getElementById("tournament_end_date")

  const commonConfig = {
    enableTime: true,
    dateFormat: "d.m.Y H:i",
    time_24hr: true,
  }

  if (startInput) {
    window.flatpickr(startInput, {
      ...commonConfig,
      defaultDate: startInput.dataset.value || undefined,
      onChange(selectedDates) {
        startHidden.value = selectedDates[0] ? flatpickr.formatDate(selectedDates[0], "Y-m-d H:i") : ""
      }
    })
  }

  if (endInput) {
    window.flatpickr(endInput, {
      ...commonConfig,
      defaultDate: endInput.dataset.value || undefined,
      onChange(selectedDates) {
        endHidden.value = selectedDates[0] ? flatpickr.formatDate(selectedDates[0], "Y-m-d H:i") : ""
      }
    })
  }
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


document.addEventListener("click", (e) => {
  const btn = e.target.closest("[data-copy-url]")
  if (!btn) return
  const url = btn.dataset.copyUrl
  const icon = btn.querySelector("i")
  const done = () => {
    if (icon) {
      icon.className = "bi bi-check-lg"
      setTimeout(() => { icon.className = "bi bi-link-45deg" }, 2000)
    }
  }
  if (navigator.clipboard) {
    navigator.clipboard.writeText(url).then(done).catch(() => fallbackCopy(url, done))
  } else {
    fallbackCopy(url, done)
  }
})

function fallbackCopy(text, done) {
  const ta = document.createElement("textarea")
  ta.value = text
  ta.style.cssText = "position:fixed;opacity:0"
  document.body.appendChild(ta)
  ta.focus()
  ta.select()
  try { document.execCommand("copy"); done() } finally { ta.remove() }
}

document.addEventListener("submit", (e) => {
  if (e.target.dataset.scrollToTop) {
    sessionStorage.setItem("scroll_to_top", "1")
  } else if (e.target.dataset.turbo === "false") {
    sessionStorage.setItem("scroll_restore_x", window.scrollX)
    sessionStorage.setItem("scroll_restore_y", window.scrollY)
    sessionStorage.setItem("scroll_restore_from", location.pathname)
  }
})

document.addEventListener("turbo:submit-start", () => {
  sessionStorage.setItem("scroll_restore_x", window.scrollX)
  sessionStorage.setItem("scroll_restore_y", window.scrollY)
  sessionStorage.setItem("scroll_restore_from", location.pathname)
})

document.addEventListener("turbo:load", () => {
  if (sessionStorage.getItem("scroll_to_top")) {
    sessionStorage.removeItem("scroll_to_top")
    window.scrollTo(0, 0)
  } else {
    const fromPath = sessionStorage.getItem("scroll_restore_from")
    if (fromPath && fromPath === location.pathname) {
      const x = parseInt(sessionStorage.getItem("scroll_restore_x"))
      const y = parseInt(sessionStorage.getItem("scroll_restore_y"))
      window.scrollTo(x, y)
    }
  }
  sessionStorage.removeItem("scroll_restore_x")
  sessionStorage.removeItem("scroll_restore_y")
  sessionStorage.removeItem("scroll_restore_from")

  initTomSelects(); initAutoSubmitFilters(); initDateTimePickers()
})
document.addEventListener("turbo:render", () => { initTomSelects(); initAutoSubmitFilters(); initDateTimePickers() })
