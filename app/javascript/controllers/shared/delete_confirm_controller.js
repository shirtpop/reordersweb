import { Controller } from "@hotwired/stimulus"

// Handles a page's primary delete modal (Order, Client::Product) and, where a page also
// has a shared per-row variant delete modal, that second one too — kept on one controller
// since only one of the two is ever open at a time.
export default class extends Controller {
  static targets = ["modal", "variantModal"]

  // No preventDefault here: the triggers are real links carrying data-turbo-frame,
  // and Turbo needs to see the click as unhandled so it can navigate that frame itself.
  open() {
    this.modalTarget.classList.remove("hidden")
    document.body.style.overflow = "hidden"
  }

  openVariant() {
    this.variantModalTarget.classList.remove("hidden")
    document.body.style.overflow = "hidden"
  }

  close(event) {
    if (event) event.preventDefault()
    if (this.hasModalTarget) this.modalTarget.classList.add("hidden")
    if (this.hasVariantModalTarget) this.variantModalTarget.classList.add("hidden")
    document.body.style.overflow = ""
  }
}
