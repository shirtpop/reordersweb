import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["overlay", "frame"]

  show() {
    this.overlayTarget.classList.remove("hidden")
  }

  close() {
    this.overlayTarget.classList.add("hidden")
    this.frameTarget.innerHTML = ""
  }

  closeOnBackdrop(event) {
    if (event.target === this.overlayTarget) {
      this.close()
    }
  }

  handleSubmitEnd(event) {
    if (event.detail.success) {
      this.close()
    }
  }

  updateCount() {
    const checkboxes = this.frameTarget.querySelectorAll("input[name='inventory_ids[]']")

    checkboxes.forEach(cb => {
      const qtyInput = cb.closest("[data-row]")?.querySelector("[data-qty-input]")
      if (qtyInput) qtyInput.disabled = !cb.checked
    })

    const checked = Array.from(checkboxes).filter(cb => cb.checked).length
    const counter = this.frameTarget.querySelector("[data-count-display]")
    const submit = this.frameTarget.querySelector("[data-submit-button]")

    if (counter) {
      counter.textContent = `${checked} variant${checked !== 1 ? "s" : ""} selected`
    }
    if (submit) {
      submit.disabled = checked === 0
      submit.textContent = checked === 0 ? "Add to Basket" : `Add ${checked} to Basket`
    }
  }

  selectAllInStock() {
    const enabled = Array.from(
      this.frameTarget.querySelectorAll("input[name='inventory_ids[]']:not([disabled])")
    )
    const allChecked = enabled.every(cb => cb.checked)
    enabled.forEach(cb => { cb.checked = !allChecked })
    this.updateCount()
  }

  clearSelection() {
    this.frameTarget
      .querySelectorAll("input[name='inventory_ids[]']")
      .forEach(cb => { cb.checked = false })
    this.updateCount()
  }
}
