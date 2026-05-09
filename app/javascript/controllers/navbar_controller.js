import { Controller } from "@hotwired/stimulus"
import { Collapse } from "bootstrap"

export default class extends Controller {
  static targets = ["menu"]

  toggle() {
    const collapse = Collapse.getOrCreateInstance(this.menuTarget)
    collapse.toggle()
  }
}
