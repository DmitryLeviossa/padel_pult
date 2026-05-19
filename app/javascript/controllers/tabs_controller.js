import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.activateTabFromHash()

    this._loadHandler = () => this.activateTabFromHash()
    document.addEventListener("turbo:load", this._loadHandler)

    this.element.querySelectorAll("[data-bs-toggle='tab']").forEach((tab) => {
      tab.addEventListener("shown.bs.tab", this.updateHash.bind(this))
    })
  }

  disconnect() {
    document.removeEventListener("turbo:load", this._loadHandler)

    this.element.querySelectorAll("[data-bs-toggle='tab']").forEach((tab) => {
      tab.removeEventListener("shown.bs.tab", this.updateHash.bind(this))
    })
  }

  activateTabFromHash() {
    const hash = window.location.hash
    if (!hash) return
    const target = this.element.querySelector(`[data-bs-target="${hash}"]`)
    if (target) {
      const { Tab } = window.bootstrap || bootstrap
      Tab.getOrCreateInstance(target).show()
    }
  }

  updateHash(event) {
    const target = event.target.getAttribute("data-bs-target")
    history.replaceState(null, "", target)
  }
}
