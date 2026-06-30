import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["step", "indicator", "prevButton", "nextButton", "submitButton", "stepCount"]
  static values = { current: { type: Number, default: 0 } }

  connect() {
    this.totalSteps = this.stepTargets.length
    this.showStep(this.currentValue)
    this.routeToErrorStep()
  }

  async next() {
    if (!this.validateCurrentStep()) return

    const step = this.currentValue + 1 // 1-indexed for server
    const mainForm = this.element.querySelector('form')
    const formData = new FormData(mainForm)

    // Ensure same_as_main checkbox is sent correctly (unchecked checkboxes don't appear in FormData)
    const sameAsMain = mainForm.querySelector('input[name="same_as_main"]')
    if (sameAsMain) formData.set('same_as_main', sameAsMain.checked ? '1' : '0')

    formData.set('step', step)

    try {
      const response = await fetch('/admin/clients/validate_step', {
        method: 'POST',
        headers: {
          'Accept': 'text/vnd.turbo-stream.html',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.content
        },
        body: formData
      })

      if (!response.ok) {
        this.advanceStep()
        return
      }

      const html = await response.text()

      // Determine validity from the raw HTML — avoids timing issues with Turbo DOM updates
      const isValid = html.includes('data-validation-passed="true"')

      // Apply the Turbo Stream to update error display in the DOM
      Turbo.renderStreamMessage(html)

      if (isValid) {
        delete this.indicatorTargets[this.currentValue].dataset.stepError
        this.indicatorTargets[this.currentValue].dataset.stepValidated = 'true'
        this.advanceStep()
      } else {
        this.indicatorTargets[this.currentValue].dataset.stepError = 'true'
        this.showStep(this.currentValue)
      }
    } catch (_e) {
      this.advanceStep()
    }
  }

  advanceStep() {
    if (this.currentValue < this.totalSteps - 1) {
      this.currentValue++
      this.showStep(this.currentValue)
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
      const hasError = indicator.dataset.stepError === 'true'

      if (hasError) {
        indicator.classList.remove("bg-gray-200", "dark:bg-gray-700", "bg-blue-600", "bg-green-500")
        indicator.classList.add("bg-red-500")
        indicator.querySelector('[data-role="number"]')?.classList.remove("hidden")
        indicator.querySelector('[data-role="check"]')?.classList.add("hidden")
      } else if (i < index) {
        indicator.classList.remove("bg-gray-200", "dark:bg-gray-700", "bg-blue-600", "bg-red-500")
        indicator.classList.add("bg-green-500")
        indicator.querySelector('[data-role="number"]')?.classList.add("hidden")
        indicator.querySelector('[data-role="check"]')?.classList.remove("hidden")
      } else if (i === index) {
        indicator.classList.remove("bg-gray-200", "dark:bg-gray-700", "bg-green-500", "bg-red-500")
        indicator.classList.add("bg-blue-600")
        indicator.querySelector('[data-role="number"]')?.classList.remove("hidden")
        indicator.querySelector('[data-role="check"]')?.classList.add("hidden")
      } else {
        indicator.classList.remove("bg-blue-600", "bg-green-500", "bg-red-500")
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
      currentStep.querySelector(".border-red-500")?.focus()
    }

    return valid
  }

  routeToErrorStep() {
    const errorExplanation = document.getElementById('error_explanation')
    if (!errorExplanation) return

    const FIELD_STEP_MAP = {
      company_name: 1, personal_name: 1, phone_number: 1,
      street: 1, city: 1, state: 1, zip_code: 1,
      email: 2, password: 2,
      catalog_name: 3,
    }

    let minStep = null
    errorExplanation.querySelectorAll('li').forEach(li => {
      const text = li.textContent.toLowerCase()
      Object.entries(FIELD_STEP_MAP).forEach(([field, step]) => {
        if (text.includes(field.replace('_', ' '))) {
          if (minStep === null || step < minStep) minStep = step
        }
      })
    })

    if (minStep !== null) {
      this.currentValue = minStep - 1
      this.showStep(this.currentValue)
    }
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
