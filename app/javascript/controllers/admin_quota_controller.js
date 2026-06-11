import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "saved"]

  #timer

  save() {
    clearTimeout(this.#timer)
    this.#timer = setTimeout(() => this.#submit(), 600)
  }

  async #submit() {
    const form = this.element
    const response = await fetch(form.action, {
      method: "PATCH",
      headers: { "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content },
      body: new FormData(form)
    })

    if (response.ok && this.hasSavedTarget) {
      this.savedTarget.classList.remove("d-none")
      setTimeout(() => this.savedTarget.classList.add("d-none"), 2000)
    }
  }
}
