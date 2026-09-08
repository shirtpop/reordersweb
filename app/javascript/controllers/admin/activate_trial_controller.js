import { Controller } from "@hotwired/stimulus"

// Popup on a trial-client user's row that lets the admin set a password for manual
// handover instead of emailing it. Scoped per row, since each row's modal is independent.
export default class extends Controller {
  static targets = ["modal"]

  open(event) {
    event.preventDefault()
    this.modalTarget.classList.remove("hidden")
  }

  close(event) {
    if (event) event.preventDefault()
    this.modalTarget.classList.add("hidden")
  }
}
