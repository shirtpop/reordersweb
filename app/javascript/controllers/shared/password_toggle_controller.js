import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "icon"]

  toggle() {
    if (!this.hasInputTarget) return

    const input = this.inputTarget
    input.type = input.type === "password" ? "text" : "password"

    if (this.hasIconTarget) {
      this.iconTarget.classList.toggle("text-gray-500")
      this.iconTarget.classList.toggle("text-pink-600")
    }
  }
}
