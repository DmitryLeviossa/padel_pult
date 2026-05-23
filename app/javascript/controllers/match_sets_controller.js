import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["list", "template"]

  connect() {
    this.updateRemoveButtons()
  }

  addSet() {
    const index = this.listTarget.querySelectorAll(".set-row").length
    const setNum = index + 1
    const html = this.templateTarget.innerHTML
      .replace(/__INDEX__/g, index)
      .replace(/__SET_NUM__/g, setNum)
      .replace(/__SET_LABEL__/g, `Сет ${setNum}`)
    this.listTarget.insertAdjacentHTML("beforeend", html)
    this.updateRemoveButtons()
  }

  removeSet(event) {
    event.currentTarget.closest(".set-row").remove()
    this.reindex()
    this.updateRemoveButtons()
  }

  reindex() {
    this.listTarget.querySelectorAll(".set-row").forEach((row, i) => {
      const setNum = i + 1
      row.querySelectorAll("input").forEach(input => {
        if (input.name) {
          input.name = input.name.replace(/\[match_sets_attributes\]\[\d+\]/, `[match_sets_attributes][${i}]`)
        }
        if (input.type === "hidden" && input.name && input.name.includes("set_number")) {
          input.value = setNum
        }
      })
      const label = row.querySelector("p.fw-semibold")
      if (label) label.textContent = `Сет ${setNum}`
    })
  }

  updateRemoveButtons() {
    const rows = this.listTarget.querySelectorAll(".set-row")
    rows.forEach(row => {
      const btn = row.querySelector("[data-action='match-sets#removeSet']")
      if (btn) btn.disabled = rows.length <= 1
    })
  }
}
