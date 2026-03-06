import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["step", "indicator", "prevButton", "nextButton", "submitButton", "stepCount"]
  static values = { current: { type: Number, default: 0 } }

  connect() {
    this.totalSteps = this.stepTargets.length
    this.showStep(this.currentValue)
  }

  next() {
    if (this.validateCurrentStep()) {
      if (this.currentValue < this.totalSteps - 1) {
        this.currentValue++
        this.showStep(this.currentValue)
      }
    }
  }

  prev() {
    if (this.currentValue > 0) {
      this.currentValue--
      this.showStep(this.currentValue)
    }
  }

  goToStep(event) {
    const step = parseInt(event.currentTarget.dataset.step)
    if (step <= this.currentValue) {
      this.currentValue = step
      this.showStep(this.currentValue)
    }
  }

  showStep(index) {
    this.stepTargets.forEach((step, i) => {
      step.classList.toggle("hidden", i !== index)
    })

    this.indicatorTargets.forEach((indicator, i) => {
      if (i < index) {
        // Completed step
        indicator.classList.remove("bg-gray-200", "dark:bg-gray-700", "bg-blue-600")
        indicator.classList.add("bg-green-500")
        indicator.querySelector('[data-role="number"]')?.classList.add("hidden")
        indicator.querySelector('[data-role="check"]')?.classList.remove("hidden")
      } else if (i === index) {
        // Current step
        indicator.classList.remove("bg-gray-200", "dark:bg-gray-700", "bg-green-500")
        indicator.classList.add("bg-blue-600")
        indicator.querySelector('[data-role="number"]')?.classList.remove("hidden")
        indicator.querySelector('[data-role="check"]')?.classList.add("hidden")
      } else {
        // Future step
        indicator.classList.remove("bg-blue-600", "bg-green-500")
        indicator.classList.add("bg-gray-200", "dark:bg-gray-700")
        indicator.querySelector('[data-role="number"]')?.classList.remove("hidden")
        indicator.querySelector('[data-role="check"]')?.classList.add("hidden")
      }
    })

    // Button visibility
    this.prevButtonTarget.classList.toggle("hidden", index === 0)
    this.nextButtonTarget.classList.toggle("hidden", index === this.totalSteps - 1)
    this.submitButtonTarget.classList.toggle("hidden", index !== this.totalSteps - 1)

    // Update step count
    if (this.hasStepCountTarget) {
      this.stepCountTarget.textContent = `Step ${index + 1} of ${this.totalSteps}`
    }

    // Populate review on last step
    if (index === this.totalSteps - 1) {
      this.populateReview()
    }
  }

  validateCurrentStep() {
    const currentStep = this.stepTargets[this.currentValue]
    const requiredFields = currentStep.querySelectorAll("[required]")
    let valid = true

    requiredFields.forEach(field => {
      if (!field.value.trim()) {
        field.classList.add("border-red-500")
        valid = false
      } else {
        field.classList.remove("border-red-500")
      }
    })

    if (!valid) {
      const firstInvalid = currentStep.querySelector(".border-red-500")
      firstInvalid?.focus()
    }

    return valid
  }

  populateReview() {
    const reviewTarget = this.element.querySelector('[data-role="review-content"]')
    if (!reviewTarget) return

    const getValue = (name) => {
      const field = this.element.querySelector(`[name="${name}"]`)
      return field?.value || "N/A"
    }

    reviewTarget.innerHTML = `
      <div class="space-y-4">
        <div>
          <h4 class="text-sm font-semibold text-gray-700 dark:text-gray-300">Company</h4>
          <p class="text-sm text-gray-900 dark:text-white">${this.escapeHtml(getValue("client[company_name]"))} - ${this.escapeHtml(getValue("client[personal_name]"))}</p>
          <p class="text-sm text-gray-500">${this.escapeHtml(getValue("client[phone_number]"))}</p>
        </div>
        <div>
          <h4 class="text-sm font-semibold text-gray-700 dark:text-gray-300">User Email</h4>
          <p class="text-sm text-gray-900 dark:text-white">${this.escapeHtml(getValue("client[users_attributes][0][email]"))}</p>
        </div>
        <div>
          <h4 class="text-sm font-semibold text-gray-700 dark:text-gray-300">Catalog</h4>
          <p class="text-sm text-gray-900 dark:text-white">${this.escapeHtml(getValue("catalog_name") || "Default Catalog")}</p>
        </div>
        <div>
          <h4 class="text-sm font-semibold text-gray-700 dark:text-gray-300">Products</h4>
          <p class="text-sm text-gray-900 dark:text-white">${this.countSelectedProducts()} products selected</p>
        </div>
      </div>
    `
  }

  countSelectedProducts() {
    return this.element.querySelectorAll('input[name="product_ids[]"]').length
  }

  escapeHtml(text) {
    const div = document.createElement('div')
    div.textContent = text
    return div.innerHTML
  }
}
