import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "confirmButton", "summaryName", "summaryEmail", "summaryItemCount"]

  connect() {
    this.form = document.getElementById("drawer-checkout-form")
    this.boundHandleSubmit = () => this.handleSubmit()
    this.form?.addEventListener("submit", this.boundHandleSubmit)
  }

  disconnect() {
    this.form?.removeEventListener("submit", this.boundHandleSubmit)
  }

  open(event) {
    event.preventDefault()

    if (!this.form || !this.form.reportValidity()) return

    const firstName = this.form.querySelector("[name='client_checkout[recipient_first_name]']")?.value.trim() || ""
    const lastName = this.form.querySelector("[name='client_checkout[recipient_last_name]']")?.value.trim() || ""
    const email = this.form.querySelector("[name='client_checkout[recipient_email]']")?.value.trim() || ""
    const itemCount = document.getElementById("checkout-drawer-item-count")?.textContent?.trim()

    this.summaryNameTarget.textContent = [firstName, lastName].filter(Boolean).join(" ") || "—"
    this.summaryEmailTarget.textContent = email || "—"
    this.summaryItemCountTarget.textContent = itemCount || "—"

    this.modalTarget.classList.remove("hidden")
    document.body.style.overflow = "hidden"
  }

  close(event) {
    if (event) event.preventDefault()
    this.modalTarget.classList.add("hidden")
    document.body.style.overflow = ""
  }

  // Hooked to the external form's "submit" event (not the button's "click") so that
  // disabling the button never races with — and cancels — the native submission.
  handleSubmit() {
    this.confirmButtonTarget.disabled = true
    this.confirmButtonTarget.textContent = "Processing..."
  }
}
