// app/javascript/controllers/client/order_form_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["grandTotal", "priceField", "submitBtn", "quantityField", "modal", "deliveryDate", 
                    "orderSummary", "emptyState", "totalItems", "totalQuantity", "totalPrice"]

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

    this.populateOrderSummary()

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

  populateOrderSummary() {
    const orderItems = this.getAllOrderItems()
    const deliveryDate = document.querySelector('[name="order[delivery_date]"]').value
    
    // Update delivery date
    this.deliveryDateTarget.textContent = this.formatDate(deliveryDate)
    
    // Clear existing summary
    this.orderSummaryTarget.innerHTML = ''
    
    if (orderItems.length === 0) {
      this.emptyStateTarget.classList.remove('hidden')
      this.orderSummaryTarget.classList.add('hidden')
      return
    }
    
    this.emptyStateTarget.classList.add('hidden')
    this.orderSummaryTarget.classList.remove('hidden')
    
    // Group items by product
    const groupedItems = this.groupItemsByProduct(orderItems)
    
    // Generate HTML for each product
    Object.entries(groupedItems).forEach(([productName, items]) => {
      const productSummaryHtml = this.createProductSummaryHtml(productName, items)
      this.orderSummaryTarget.insertAdjacentHTML('beforeend', productSummaryHtml)
    })
    
    // Update totals
    this.updateModalTotals(orderItems)
  }

  getAllOrderItems() {
    const items = []
    
    // Get all product cards
    const productCards = document.querySelectorAll('.product-card')
    
    productCards.forEach(card => {
      const productName = card.querySelector('h2').textContent.trim()
      const productId = card.dataset.productId
      const itemContainers = card.querySelectorAll('[data-item-id]')
      
      itemContainers.forEach(container => {
        const itemId = container.dataset.itemId
        const colorElement = container.querySelector('[data-color]')
        const color = colorElement ? colorElement.textContent.trim() : 'Unknown'
        const colorHex = container.querySelector('.w-4.h-4')?.style.backgroundColor || '#000000'
        
        const sizes = {}
        let totalQuantity = 0
        
        // Get quantities for each size
        container.querySelectorAll('.size-quantity').forEach(input => {
          const size = input.dataset.size
          const quantity = parseInt(input.value) || 0
          if (quantity > 0) {
            sizes[size] = quantity
            totalQuantity += quantity
          }
        })
        
        if (totalQuantity > 0) {
          items.push({
            productId,
            productName,
            itemId,
            color,
            colorHex,
            sizes,
            totalQuantity,
            unitPrice: this.calculateItemPrice(productId, totalQuantity),
            totalPrice: this.calculateItemPrice(productId, totalQuantity) * totalQuantity
          })
        }
      })
    })
    
    return items
  }

  groupItemsByProduct(items) {
    return items.reduce((grouped, item) => {
      if (!grouped[item.productName]) {
        grouped[item.productName] = []
      }
      grouped[item.productName].push(item)
      return grouped
    }, {})
  }

  createProductSummaryHtml(productName, items) {
    const itemsHtml = items.map(item => `
      <div class="bg-gray-50 rounded-lg p-3 border border-gray-200">
        <div class="flex items-center gap-3 mb-2">
          <div class="w-4 h-4 rounded-full border border-gray-300" 
              style="background-color: ${item.colorHex}"></div>
          <span class="font-medium text-gray-900">${item.color}</span>
          <span class="text-sm text-gray-500">(${item.totalQuantity} total)</span>
        </div>
        
        <div class="grid grid-cols-2 md:grid-cols-4 gap-2 text-sm">
          ${Object.entries(item.sizes).map(([size, qty]) => `
            <div class="flex justify-between">
              <span class="text-gray-600">${size}:</span>
              <span class="font-medium">${qty}</span>
            </div>
          `).join('')}
        </div>
        
        <div class="flex justify-between items-center mt-2 pt-2 border-t border-gray-300">
          <span class="text-sm text-gray-600">Item Total:</span>
          <span class="font-medium text-pink-600">$${item.totalPrice.toFixed(2)}</span>
        </div>
      </div>
    `).join('')
    
    const productTotal = items.reduce((sum, item) => sum + item.totalPrice, 0)
    
    return `
      <div class="border border-gray-200 rounded-lg p-4 mb-4">
        <div class="flex justify-between items-center mb-3">
          <h5 class="font-semibold text-gray-900">${productName}</h5>
          <span class="text-lg font-bold text-pink-600">$${productTotal.toFixed(2)}</span>
        </div>
        <div class="space-y-3">
          ${itemsHtml}
        </div>
      </div>
    `
  }

  updateModalTotals(items) {
    const totalItems = items.length
    const totalQuantity = items.reduce((sum, item) => sum + item.totalQuantity, 0)
    const totalPrice = items.reduce((sum, item) => sum + item.totalPrice, 0)
    
    this.totalItemsTarget.textContent = totalItems
    this.totalQuantityTarget.textContent = totalQuantity
    this.totalPriceTarget.textContent = `$${totalPrice.toFixed(2)}`
  }

  calculateItemPrice(productId, quantity) {
    // Get product data (you might need to adjust this based on your data structure)
    const productCard = document.querySelector(`[data-product-id="${productId}"]`)
    const basePrice = parseFloat(productCard.dataset.basePrice)
    const bulkPrices = JSON.parse(productCard.dataset.bulkPrice || '[]')
    
    // Find applicable bulk price
    let unitPrice = basePrice
    for (const bulk of bulkPrices.sort((a, b) => b.qty - a.qty)) {
      if (quantity >= parseInt(bulk.qty)) {
        unitPrice = parseFloat(bulk.price)
        break
      }
    }
    
    return unitPrice
  }

  formatDate(dateString) {
    if (!dateString) return 'Not specified'
    
    const date = new Date(dateString)
    return date.toLocaleDateString('en-US', {
      weekday: 'long',
      year: 'numeric',
      month: 'long',
      day: 'numeric'
    })
  }
}