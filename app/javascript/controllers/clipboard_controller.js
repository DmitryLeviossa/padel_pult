import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { text: String }

  copy() {
    const text = this.textValue
    if (!text) return

    const succeed = () => {
      const original = this.element.textContent
      this.element.textContent = "✓ Скопировано"
      setTimeout(() => { this.element.textContent = original }, 2000)
    }

    if (navigator.clipboard) {
      navigator.clipboard.writeText(text).then(succeed).catch(() => this.#fallback(text, succeed))
    } else {
      this.#fallback(text, succeed)
    }
  }

  #fallback(text, succeed) {
    const ta = document.createElement("textarea")
    ta.value = text
    ta.style.cssText = "position:fixed;opacity:0"
    document.body.appendChild(ta)
    ta.focus()
    ta.select()
    try {
      document.execCommand("copy")
      succeed()
    } finally {
      ta.remove()
    }
  }
}
