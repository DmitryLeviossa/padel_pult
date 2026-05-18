import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    const hash = window.location.hash
    if (hash) {
      const target = this.element.querySelector(`[data-bs-target="${hash}"]`)
      if (target) {
        const { Tab } = window.bootstrap || bootstrap
        Tab.getOrCreateInstance(target).show()
      }
    }

    this.element.querySelectorAll("[data-bs-toggle='tab']").forEach((tab) => {
      tab.addEventListener("shown.bs.tab", this.updateHash.bind(this))
    })
  }

  disconnect() {
    this.element.querySelectorAll("[data-bs-toggle='tab']").forEach((tab) => {
      tab.removeEventListener("shown.bs.tab", this.updateHash.bind(this))
    })
  }

  updateHash(event) {
    const target = event.target.getAttribute("data-bs-target")
    history.replaceState(null, "", target)
  }
}
