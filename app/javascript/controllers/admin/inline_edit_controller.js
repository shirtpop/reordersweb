import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["display", "form"]

  edit() {
    this.displayTarget.classList.add("hidden")
    this.formTarget.classList.remove("hidden")
    const input = this.formTarget.querySelector("input[type='text']")
    if (input) {
      input.focus()
      input.select()
    }
  }

  cancel() {
    this.formTarget.classList.add("hidden")
    this.displayTarget.classList.remove("hidden")
  }
}
