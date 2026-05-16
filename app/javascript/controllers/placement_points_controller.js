import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["list", "template"]

  addRow() {
    const index = this.listTarget.querySelectorAll(".placement-row").length
    const html = this.templateTarget.innerHTML.replace(/__INDEX__/g, index)
    this.listTarget.insertAdjacentHTML("beforeend", html)
  }

  removeRow(event) {
    event.currentTarget.closest(".placement-row").remove()
    this.reindex()
  }

  reindex() {
    this.listTarget.querySelectorAll(".placement-row").forEach((row, i) => {
      row.querySelectorAll("input").forEach(input => {
        input.name = input.name.replace(/\[\d+\]/, `[${i}]`)
      })
    })
  }
}
