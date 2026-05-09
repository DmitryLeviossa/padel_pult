import { Controller } from "@hotwired/stimulus"
import { Collapse } from "bootstrap"

export default class extends Controller {
  static targets = ["menu"]

  toggle() {
    const collapse = Collapse.getOrCreateInstance(this.menuTarget)
    collapse.toggle()

    this.menuTarget.addEventListener("shown.bs.collapse", () => {
      this.element.querySelector(".navbar-toggler").setAttribute("aria-expanded", "true")
    }, { once: true })
    this.menuTarget.addEventListener("hidden.bs.collapse", () => {
      this.element.querySelector(".navbar-toggler").setAttribute("aria-expanded", "false")
    }, { once: true })
  }
}
