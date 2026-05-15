// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import "bootstrap"
function initTomSelects() {
  document.querySelectorAll("select.form-select:not(.ts-hidden-accessible)").forEach(el => {
    new window.TomSelect(el, { allowEmptyOption: true })
  })
}

document.addEventListener("turbo:load", initTomSelects)
document.addEventListener("turbo:render", initTomSelects)
