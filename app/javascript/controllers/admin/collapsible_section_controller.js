import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "icon"]
  static values = { open: { type: Boolean, default: true } }

  connect() {
    this.render()
  }

  toggle() {
    this.openValue = !this.openValue
    this.render()
  }

  render() {
    if (this.openValue) {
      this.contentTarget.classList.remove("hidden")
      this.iconTarget.classList.add("rotate-180")
    } else {
      this.contentTarget.classList.add("hidden")
      this.iconTarget.classList.remove("rotate-180")
    }
  }

  open() {
    if (!this.openValue) {
      this.openValue = true
      this.render()
    }
  }
}
