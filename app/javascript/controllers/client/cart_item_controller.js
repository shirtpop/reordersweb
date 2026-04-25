import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["quantityInput", "form"]
  static values = {
    debounce: { type: Number, default: 800 }
  }

  connect() {
    this.timeout = null
  }

  disconnect() {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
  }

  updateQuantity(event) {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }

    const quantity = parseInt(this.quantityInputTarget.value || 0)

    if (quantity < 0) {
      this.quantityInputTarget.value = 0
      return
    }

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
      if (typeof this.formTarget.requestSubmit === 'function') {
        this.formTarget.requestSubmit()
      } else {
        this.formTarget.submit()
      }
    }
  }
}
