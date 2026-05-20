import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["mixedConfig", "olympicConfig"]

  connect() {
    this.toggle()
  }

  toggle() {
    const select = this.element.querySelector("select[data-tournament-type-select]")
    const type = select?.value
    this.mixedConfigTarget.classList.toggle("d-none", type !== "mixed")
    this.olympicConfigTarget.classList.toggle("d-none", type !== "olympic")
  }
}
