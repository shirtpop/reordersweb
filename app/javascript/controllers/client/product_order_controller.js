// app/javascript/controllers/client/product_order_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["itemsContainer", "productTotal", "hiddenFields"]
  
  connect() {
    this.selectedColor = null
    this.selectedColorHex = null
    this.itemIndex = 0
    this.usedColors = new Set() // Track used colors
    this.initializeProductData()
  }
  
  initializeProductData() {
    // Get product data from data attributes
    this.productData = {
      id: this.element.dataset.productId,
      basePrice: parseFloat(this.element.dataset.basePrice),
      bulkPrice: JSON.parse(this.element.dataset.bulkPrice || '[]'),
      minimumOrder: parseInt(this.element.dataset.minimumOrder),
      sizes: JSON.parse(this.element.dataset.sizes || '[]')
    }
  }
  
  selectColor(event) {
    const colorName = event.currentTarget.dataset.color
    
    // Check if color is already used
    if (this.usedColors.has(colorName)) {
      this.showColorUsedAlert(colorName)
      return
    }
    
    // Remove selection from other colors
    this.element.querySelectorAll('.color-selector').forEach(btn => {
      btn.classList.remove('border-pink-500', 'bg-pink-50')
    })
    
    // Add selection to clicked color
    event.currentTarget.classList.add('border-pink-500', 'bg-pink-50')
    
    this.selectedColor = colorName
    this.selectedColorHex = event.currentTarget.dataset.hex
    
    // Enable add button
    const addBtn = this.element.querySelector('.add-item-btn')
    addBtn.disabled = false
  }
  
  addColorItem() {
    if (!this.selectedColor) return
    
    const itemId = `item_${this.productData.id}_${this.itemIndex++}`
    
    const itemHtml = this.createItemHtml(itemId)
    this.itemsContainerTarget.insertAdjacentHTML('beforeend', itemHtml)
    
    // Add color to used colors set
    this.usedColors.add(this.selectedColor)
    
    // Disable the selected color button
    this.disableUsedColorButton(this.selectedColor)
    
    // Reset color selection
    this.resetColorSelection()
    this.updateProductTotal()
  }
  
  createItemHtml(itemId) {
    const sizesHtml = this.productData.sizes.map(size => `
      <div class="flex flex-col">
        <label class="text-xs font-medium text-gray-600 mb-1">${size}</label>
        <input type="number" 
               class="size-quantity bg-white border border-gray-300 text-gray-900 text-sm rounded-lg focus:ring-pink-500 focus:border-pink-500 p-2"
               min="0" 
               placeholder="0"
               data-action="input->product-order#updateQuantity"
               data-size="${size}"
               data-item-id="${itemId}">
      </div>
    `).join('')
    
    return `
      <div class="border border-pink-200 rounded-lg p-4 bg-pink-50" data-item-id="${itemId}">
        <div class="flex justify-between items-start mb-3">
          <div class="flex items-center gap-2">
            <div class="w-4 h-4 rounded-full border border-gray-300" 
                 style="background-color: ${this.selectedColorHex}"></div>
            <span class="font-medium text-gray-900" data-color="${this.selectedColor}">${this.selectedColor}</span>
          </div>
          <button type="button" 
                  class="text-red-600 hover:text-red-800 text-sm"
                  data-action="click->product-order#removeItem"
                  data-item-id="${itemId}">
            Remove
          </button>
        </div>
        
        <div class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-3 mb-3">
          ${sizesHtml}
        </div>
        
        <div class="pt-3 border-t border-pink-200">
          <div class="flex justify-between items-center text-sm mb-2">
            <span class="text-gray-600">Total Quantity:</span>
            <span class="item-quantity font-medium">0</span>
          </div>
          <div class="text-xs text-red-600 validation-message hidden"></div>
        </div>
      </div>
    `
  }
  
  resetColorSelection() {
    this.element.querySelectorAll('.color-selector').forEach(btn => {
      btn.classList.remove('border-pink-500', 'bg-pink-50')
    })
    this.selectedColor = null
    this.selectedColorHex = null
    this.element.querySelector('.add-item-btn').disabled = true
  }
  
  disableUsedColorButton(colorName) {
    this.element.querySelectorAll('.color-selector').forEach(btn => {
      if (btn.dataset.color === colorName) {
        btn.disabled = true
        btn.classList.add('opacity-50', 'cursor-not-allowed')
        btn.classList.remove('hover:border-pink-500')
      }
    })
  }
  
  enableColorButton(colorName) {
    this.element.querySelectorAll('.color-selector').forEach(btn => {
      if (btn.dataset.color === colorName) {
        btn.disabled = false
        btn.classList.remove('opacity-50', 'cursor-not-allowed')
        btn.classList.add('hover:border-pink-500')
      }
    })
  }
  
  removeItem(event) {
    const itemId = event.currentTarget.dataset.itemId
    const itemElement = this.element.querySelector(`[data-item-id="${itemId}"]`)
    if (itemElement) {
      // Get the color name before removing the item
      const colorElement = itemElement.querySelector('[data-color]')
      const colorName = colorElement ? colorElement.dataset.color : null
      
      // Remove from used colors set and re-enable button
      if (colorName) {
        this.usedColors.delete(colorName)
        this.enableColorButton(colorName)
      }
      
      itemElement.remove()
      this.updateProductTotal()
    }
  }
  
  updateQuantity(event) {
    const itemId = event.currentTarget.dataset.itemId
    const itemElement = this.element.querySelector(`[data-item-id="${itemId}"]`)
    
    if (!itemElement) return
    
    // Update item totals
    const quantityInputs = itemElement.querySelectorAll('.size-quantity')
    let totalQuantity = 0
    
    quantityInputs.forEach(input => {
      const value = parseInt(input.value) || 0
      totalQuantity += value
    })
    
    const itemQuantitySpan = itemElement.querySelector('.item-quantity')
    itemQuantitySpan.textContent = totalQuantity
    
    this.updateProductTotal()
    this.updateHiddenFields()
  }
  
  calculatePrice(quantity) {
    if (quantity === 0) return 0
    
    // Check bulk pricing
    let price = this.productData.basePrice
    
    if (this.productData.bulkPrice && this.productData.bulkPrice.length > 0) {
      // Sort bulk prices by quantity descending
      const sortedBulkPrices = [...this.productData.bulkPrice].sort((a, b) => parseInt(b.qty) - parseInt(a.qty))
      
      for (const bulk of sortedBulkPrices) {
        if (quantity >= parseInt(bulk.qty)) {
          price = parseFloat(bulk.price)
          break
        }
      }
    }
    
    return price
  }
  
  updateProductTotal() {
    // Calculate total quantity for this product across all color items
    let totalQuantity = 0
    let totalPrice = 0
    
    this.element.querySelectorAll('[data-item-id]').forEach(item => {
      const quantityInputs = item.querySelectorAll('.size-quantity')
      
      quantityInputs.forEach(input => {
        totalQuantity += parseInt(input.value) || 0
      })
    })
    
    // Calculate price based on total quantity
    const unitPrice = this.calculatePrice(totalQuantity)
    totalPrice = totalQuantity * unitPrice
    
    // Validate minimum order
    const isValid = this.validateMinimumOrder(totalQuantity)
    
    // Update display if target exists
    if (this.hasProductTotalTarget) {
      this.productTotalTarget.textContent = `$${totalPrice.toFixed(2)}`
    }
    
    // Dispatch event to parent controller
    this.dispatch('productTotalChanged', { 
      detail: { 
        productId: this.productData.id, 
        total: totalPrice,
        quantity: totalQuantity,
        isValid: isValid,
        minimumOrder: this.productData.minimumOrder
      }
    })
  }
  
  validateMinimumOrder(totalQuantity) {
    const minimumOrder = this.productData.minimumOrder
    const isValid = totalQuantity === 0 || totalQuantity >= minimumOrder
    
    // Update validation messages for each item
    this.element.querySelectorAll('[data-item-id]').forEach(item => {
      const validationMessage = item.querySelector('.validation-message')
      
      if(validationMessage) {
        if (totalQuantity > 0 && totalQuantity < minimumOrder) {
          const remaining = minimumOrder - totalQuantity
          validationMessage.textContent = `Need ${remaining} more pieces to meet minimum order of ${minimumOrder}`
          validationMessage.classList.remove('hidden')
          item.classList.add('border-red-300', 'bg-red-50')
          item.classList.remove('border-pink-200', 'bg-pink-50')
        } else {
          validationMessage.textContent = ''
          validationMessage.classList.add('hidden')
          item.classList.remove('border-red-300', 'bg-red-50')
          item.classList.add('border-pink-200', 'bg-pink-50')
        }
      }
    })
    
    return isValid
  }
  
  updateHiddenFields() {
    let hiddenFieldsHtml = ''
    let orderItemIndex = parseInt(this.element.dataset.orderItemIndex || '0')
    
    this.element.querySelectorAll('[data-item-id]').forEach(item => {
      const colorElement = item.querySelector('[data-color]')
      const color = colorElement ? colorElement.dataset.color : ''
      
      item.querySelectorAll('.size-quantity').forEach(input => {
        const quantity = parseInt(input.value) || 0
        if (quantity > 0) {
          const size = input.dataset.size
          
          hiddenFieldsHtml += `
            <input type="hidden" name="order[order_items_attributes][${orderItemIndex}][product_id]" value="${this.productData.id}">
            <input type="hidden" name="order[order_items_attributes][${orderItemIndex}][color]" value="${color}">
            <input type="hidden" name="order[order_items_attributes][${orderItemIndex}][size]" value="${size}">
            <input type="hidden" name="order[order_items_attributes][${orderItemIndex}][quantity]" value="${quantity}">
          `
          orderItemIndex++
        }
      })
    })
    
    this.hiddenFieldsTarget.innerHTML = hiddenFieldsHtml
    // Update the order item index for next product
    this.element.dataset.orderItemIndex = orderItemIndex.toString()
  }
  
  showColorUsedAlert(colorName) {
    // Create a simple alert notification
    const alertDiv = document.createElement('div')
    alertDiv.className = 'fixed top-4 right-4 bg-yellow-100 border border-yellow-400 text-yellow-700 px-4 py-3 rounded z-50'
    alertDiv.innerHTML = `
      <div class="flex items-center">
        <span>Color "${colorName}" is already selected for this product.</span>
        <button type="button" class="ml-4 text-yellow-700 hover:text-yellow-900" onclick="this.parentElement.parentElement.remove()">
          <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
            <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd"></path>
          </svg>
        </button>
      </div>
    `
    
    document.body.appendChild(alertDiv)
    
    // Auto remove after 5 seconds
    setTimeout(() => {
      if (alertDiv.parentElement) {
        alertDiv.remove()
      }
    }, 5000)
  }
}