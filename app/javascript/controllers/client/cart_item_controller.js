import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["quantityInput", "form"]
  static values = {
    debounce: { type: Number, default: 800 }
  }

  connect() {
    this.timeout = null
    console.log("Cart item controller connected", {
      hasForm: this.hasFormTarget,
      hasInput: this.hasQuantityInputTarget
    })
  }

  disconnect() {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
  }

  updateQuantity(event) {
    // Clear existing timeout
    if (this.timeout) {
      clearTimeout(this.timeout)
    }

    // Validate quantity
    const quantity = parseInt(this.quantityInputTarget.value || 0)

    if (quantity < 0) {
      this.quantityInputTarget.value = 0
      return
    }

    console.log("Updating quantity to:", quantity)

    // Debounce the form submission
    this.timeout = setTimeout(() => {
      this.submitForm()
    }, this.debounceValue)
  }

  increment(event) {
    event.preventDefault()
    const currentValue = parseInt(this.quantityInputTarget.value || 0)
    this.quantityInputTarget.value = currentValue + 1
    this.updateQuantity()
  }

  decrement(event) {
    event.preventDefault()
    const currentValue = parseInt(this.quantityInputTarget.value || 0)
    if (currentValue > 0) {
      this.quantityInputTarget.value = currentValue - 1
      this.updateQuantity()
    }
  }

  submitForm() {
    if (this.hasFormTarget) {
      console.log("Submitting form")
      // Use requestSubmit() to trigger form validations and events
      // Falls back to submit() if requestSubmit is not available
      if (typeof this.formTarget.requestSubmit === 'function') {
        this.formTarget.requestSubmit()
      } else {
        this.formTarget.submit()
      }
    } else {
      console.error("Form target not found")
    }
  }
}
