import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["mixedConfig"]

  connect() {
    this.toggle()
  }

  toggle() {
    const select = this.element.querySelector("select[data-tournament-type-select]")
    const isMixed = select?.value === "mixed"
    this.mixedConfigTarget.classList.toggle("d-none", !isMixed)
  }
}
