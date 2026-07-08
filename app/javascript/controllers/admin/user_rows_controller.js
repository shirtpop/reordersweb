import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="user-rows"
export default class extends Controller {
  static targets = ["rows", "row", "template"]

  connect() {
    this.nextIndex = 1
  }

  add() {
    const html = this.templateTarget.innerHTML.replaceAll("NEW_RECORD", this.nextIndex)
    this.nextIndex++
    this.rowsTarget.insertAdjacentHTML("beforeend", html)
  }

  remove(event) {
    if (this.rowTargets.length <= 1) return

    event.target.closest('[data-user-rows-target~="row"]').remove()
  }
}
