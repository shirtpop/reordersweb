// app/javascript/controllers/client/order_form_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["grandTotal", "priceField", "submitBtn", "quantityField", "modal"]
  
  connect() {
    this.productTotals = {}
    this.productQuantities = {}
    this.productValidations = {}
    this.element.addEventListener('product-order:productTotalChanged', this.handleProductTotalChanged.bind(this))
  }
  
  disconnect() {
    this.element.removeEventListener('product-order:productTotalChanged', this.handleProductTotalChanged.bind(this))
  }
  
  handleProductTotalChanged(event) {
    const { productId, total, quantity, isValid, minimumOrder } = event.detail
    
    this.productTotals[productId] = total
    this.productQuantities[productId] = quantity
    this.productValidations[productId] = {
      isValid: isValid,
      quantity: quantity,
      minimumOrder: minimumOrder
    }
    
    this.updateGrandTotal()
    this.updateQuantityField()
    this.updateFormValidation()
  }
  
  updateGrandTotal() {
    const grandTotal = Object.values(this.productTotals).reduce((sum, total) => sum + total, 0)
    
    // Update display
    if (this.hasGrandTotalTarget) {
      this.grandTotalTarget.textContent = `$${grandTotal.toFixed(2)}`
    }
    
    // Update hidden field if it exists
    if (this.hasPriceFieldTarget) {
      this.priceFieldTarget.value = grandTotal.toFixed(2)
    }
  }
  
  updateQuantityField() {
    const totalQuantity = Object.values(this.productQuantities).reduce((sum, quantity) => sum + quantity, 0)
    
    if (this.hasQuantityFieldTarget) {
      this.quantityFieldTarget.value = totalQuantity
    }
  }
  
  updateFormValidation() {
    const hasItems = Object.values(this.productQuantities).some(qty => qty > 0)
    const allProductsValid = Object.values(this.productValidations).every(validation => 
      validation.quantity === 0 || validation.isValid
    )
    
    const isFormValid = hasItems && allProductsValid
    
    // Update submit button state
    if (this.hasSubmitBtnTarget) {
      if (isFormValid) {
        this.submitBtnTarget.disabled = false
        this.submitBtnTarget.classList.remove('opacity-50', 'cursor-not-allowed')
        this.submitBtnTarget.classList.add('hover:bg-pink-700')
      } else {
        this.submitBtnTarget.disabled = true
        this.submitBtnTarget.classList.add('opacity-50', 'cursor-not-allowed')
        this.submitBtnTarget.classList.remove('hover:bg-pink-700')
      }
    }
    
    // Show validation summary
    this.showValidationSummary()
  }
  
  showValidationSummary() {
    // Remove existing validation summary
    const existingSummary = this.element.querySelector('.validation-summary')
    if (existingSummary) {
      existingSummary.remove()
    }
    
    const invalidProducts = []
    Object.entries(this.productValidations).forEach(([productId, validation]) => {
      if (validation.quantity > 0 && !validation.isValid) {
        // Get product name from the DOM
        const productElement = this.element.querySelector(`[data-product-id="${productId}"]`)
        const productNameElement = productElement ? productElement.querySelector('h3') : null
        const productName = productNameElement ? productNameElement.textContent.trim() : `Product ${productId}`
        
        invalidProducts.push({
          name: productName,
          current: validation.quantity,
          minimum: validation.minimumOrder
        })
      }
    })
    
    if (invalidProducts.length > 0) {
      const summaryHtml = this.createValidationSummaryHtml(invalidProducts)
      
      // Insert before the submit button container
      const submitContainer = this.element.querySelector('.flex.flex-col.sm\\:flex-row') || 
                             this.submitBtnTarget.closest('.flex') ||
                             this.submitBtnTarget.parentElement
      if (submitContainer) {
        submitContainer.insertAdjacentHTML('beforebegin', summaryHtml)
      }
    }
  }
  
  createValidationSummaryHtml(invalidProducts) {
    const productsList = invalidProducts.map(product => 
      `<li class="text-sm">
        <strong>${product.name}:</strong> Current quantity ${product.current}, minimum required ${product.minimum}
      </li>`
    ).join('')
    
    return `
      <div class="validation-summary bg-red-50 border border-red-200 rounded-lg p-4 mb-4">
        <div class="flex items-start">
          <div class="flex-shrink-0">
            <svg class="h-5 w-5 text-red-400" viewBox="0 0 20 20" fill="currentColor">
              <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd" />
            </svg>
          </div>
          <div class="ml-3">
            <h3 class="text-sm font-medium text-red-800">
              Minimum Order Requirements Not Met
            </h3>
            <div class="mt-2 text-red-700">
              <p class="text-sm mb-2">The following products don't meet minimum order requirements:</p>
              <ul class="list-disc list-inside space-y-1">
                ${productsList}
              </ul>
            </div>
          </div>
        </div>
      </div>
    `
  }
  
  // Form validation before submit
  validateForm(event) {
    const totalQuantity = parseInt(this.quantityFieldTarget?.value) || 0
    
    if (totalQuantity === 0) {
      event.preventDefault()
      this.showAlert('Please add at least one item to your order.')
      return false
    }
    
    // Check minimum order requirements for each product
    const invalidProducts = []
    Object.entries(this.productValidations).forEach(([productId, validation]) => {
      if (validation.quantity > 0 && !validation.isValid) {
        const productElement = this.element.querySelector(`[data-product-id="${productId}"]`)
        const productNameElement = productElement ? productElement.querySelector('h3') : null
        const productName = productNameElement ? productNameElement.textContent.trim() : `Product ${productId}`
        
        invalidProducts.push({
          name: productName,
          current: validation.quantity,
          minimum: validation.minimumOrder
        })
      }
    })
    
    if (invalidProducts.length > 0) {
      event.preventDefault()
      const productDetails = invalidProducts.map(p => `${p.name} needs ${p.minimum - p.current} more pieces`).join(', ')
      this.showAlert(`Minimum order requirements not met: ${productDetails}`)
      return false
    }
    
    // Check delivery date
    const deliveryDate = this.element.querySelector('[name="order[delivery_date]"]')
    if (!deliveryDate || !deliveryDate.value) {
      event.preventDefault()
      this.showAlert('Please select a delivery date.')
      if (deliveryDate) deliveryDate.focus()
      return false
    }
    
    // Check if delivery date is in the future
    const selectedDate = new Date(deliveryDate.value)
    const today = new Date()
    today.setHours(0, 0, 0, 0)
    
    if (selectedDate < today) {
      event.preventDefault()
      this.showAlert('Delivery date must be in the future.')
      deliveryDate.focus()
      return false
    }
    
    return true
  }
  
  showAlert(message) {
    // Remove existing alerts
    const existingAlerts = document.querySelectorAll('.form-alert')
    existingAlerts.forEach(alert => alert.remove())
    
    // Create a simple alert notification
    const alertDiv = document.createElement('div')
    alertDiv.className = 'form-alert fixed top-4 right-4 bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded z-50 max-w-md shadow-lg'
    alertDiv.innerHTML = `
      <div class="flex items-start">
        <div class="flex-shrink-0">
          <svg class="h-5 w-5 text-red-400 mt-0.5" viewBox="0 0 20 20" fill="currentColor">
            <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd" />
          </svg>
        </div>
        <div class="ml-3 flex-grow">
          <span class="text-sm">${message}</span>
        </div>
        <button type="button" class="ml-4 text-red-700 hover:text-red-900 flex-shrink-0" onclick="this.parentElement.parentElement.remove()">
          <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
            <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd"></path>
          </svg>
        </button>
      </div>
    `
    
    document.body.appendChild(alertDiv)
    
    // Auto remove after 7 seconds
    setTimeout(() => {
      if (alertDiv.parentElement) {
        alertDiv.remove()
      }
    }, 7000)
  }

  validateAndConfirm(event) {
    if (!this.validateForm(event)) {
      return
    }

    // Show confirmation modal
    this.openConfirmationModal()
  }

  openConfirmationModal() {
    this.modalTarget.classList.remove("hidden")
  }

  closeConfirmation() {
    this.modalTarget.classList.add("hidden")
  }

  submitForm() {
    this.modalTarget.classList.add("hidden")
    this.element.requestSubmit() // Submit form
  }
}