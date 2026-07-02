import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["mixedConfig", "olympicConfig", "americanoConfig", "roundRobinConfig"]

  connect() {
    this.toggle()
  }

  toggle() {
    const select = this.element.querySelector("select[data-tournament-type-select]")
    const type = select?.value
    this.setVisible(this.mixedConfigTarget, type === "mixed")
    this.setVisible(this.olympicConfigTarget, type === "olympic")
    this.setVisible(this.americanoConfigTarget, type === "americano")
    this.setVisible(this.roundRobinConfigTarget, type === "round_robin")
  }

  setVisible(target, visible) {
    target.classList.toggle("d-none", !visible)
    target.querySelectorAll("input, select, textarea").forEach(el => {
      el.disabled = !visible
    })
  }
}
