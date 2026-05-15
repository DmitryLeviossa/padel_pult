import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { delay: { type: Number, default: 5000 } }

  connect() {
    this.timer = setTimeout(() => this.close(), this.delayValue)
  }

  disconnect() {
    clearTimeout(this.timer)
  }

  close() {
    this.element.classList.remove("show")

    const onTransitionEnd = () => this.element.remove()
    this.element.addEventListener("transitionend", onTransitionEnd, { once: true })

    // Fallback: if no transition fires within 200ms (e.g. prefers-reduced-motion), remove directly
    setTimeout(() => {
      this.element.removeEventListener("transitionend", onTransitionEnd)
      if (this.element.isConnected) this.element.remove()
    }, 200)
  }
}
