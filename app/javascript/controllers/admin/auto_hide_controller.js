import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { delay: Number }

  connect() {
    this.timeout = setTimeout(() => {
      this.hide()
    }, this.delayValue || 3000)
  }

  disconnect() {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
  }

  hide() {
    this.element.remove()
  }
}