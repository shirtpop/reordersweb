import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    autoDismiss: { type: Boolean, default: true },
    dismissAfter: { type: Number, default: 5000 }
  }

  connect() {
    if (this.autoDismissValue) {
      this.timeout = setTimeout(() => {
        this.dismiss()
      }, this.dismissAfterValue)
    }
  }

  disconnect() {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
  }

  dismiss() {
    // Animate out
    this.element.classList.add('animate-fade-out')

    setTimeout(() => {
      this.element.remove()
    }, 300)
  }
}
