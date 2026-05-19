import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  submit() {
    fetch(this.element.action, {
      method: "PATCH",
      body: new FormData(this.element)
    })
  }
}
