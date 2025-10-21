import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "skuInput",
    "searchError",
    "successMessage",
    "itemsContainer",
    "emptyState",
    "itemTemplate",
    "submitButton"
  ]

  connect() {
    this.itemIndex = 0
    console.log("Checkout form controller connected")
  }

  preventSubmit(event) {
    // Only prevent if the target is the SKU input field
    if (document.activeElement === this.skuInputTarget) {
      event.preventDefault()
      return false
    }
  }

  handleSkuSearch(event) {
    console.log("Key pressed:", event.key, "KeyCode:", event.keyCode)
    if (event.key === "Enter" || event.keyCode === 13) {
      event.preventDefault()
      event.stopPropagation()
      console.log("Enter detected, searching SKU")
      this.searchSku()
    }
  }

  searchSkuButton(event) {
    console.log("Add Item button clicked")
    event.preventDefault()
    event.stopPropagation()
    this.searchSku()
  }

  async searchSku() {
    console.log("searchSku called")
    const sku = this.skuInputTarget.value.trim()
    console.log("SKU value:", sku)
    
    if (!sku) {
      this.showError("Please enter a SKU")
      return
    }

    this.hideError()
    this.skuInputTarget.disabled = true

    try {
      console.log("Fetching product variant for SKU:", sku)
      const response = await fetch(`/product_variants/${encodeURIComponent(sku)}`, {
        headers: {
          'Accept': 'application/json',
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
        }
      })

      if (!response.ok) {
        throw new Error('Product variant not found')
      }

      const data = await response.json()
      const success = this.addItem(data)
      if (success) {
        this.skuInputTarget.value = ""
        this.showSuccess(`${data.product_name} (${data.sku}) added`)
      }
    } catch (error) {
      this.showError(error.message || "Product not found. Please check the SKU and try again.")
    } finally {
      this.skuInputTarget.disabled = false
      this.skuInputTarget.focus()
    }
  }

  addItem(variant) {
    // Check if item already exists
    const existingItems = this.itemsContainerTarget.querySelectorAll('[data-item-row]')
    for (const item of existingItems) {
      const existingSku = item.querySelector('[data-field="sku"]').textContent.trim()
      if (existingSku === variant.sku) {
        this.showError("This item is already in the list")
        return false
      }
    }

    // Check if inventory is available
    if (!variant.inventory_id || variant.quantity <= 0) {
      this.showError("This item is out of stock")
      return false
    }

    // Hide empty state
    if (this.hasEmptyStateTarget) {
      this.emptyStateTarget.style.display = 'none'
    }

    // Clone template
    const template = this.itemTemplateTarget.content.cloneNode(true)
    const row = template.querySelector('[data-item-row]')

    // Fill in the data
    row.querySelector('[data-field="product-name"]').textContent = variant.product_name
    row.querySelector('[data-field="sku"]').textContent = variant.sku
    row.querySelector('[data-field="color"]').textContent = variant.color || 'N/A'
    row.querySelector('[data-field="size"]').textContent = variant.size || 'N/A'
    row.querySelector('[data-field="available"]').textContent = `${variant.quantity} units`

    // Update form field names with unique index
    const quantityInput = row.querySelector('[data-field="quantity-input"]')
    const inventoryIdInput = row.querySelector('[data-field="inventory-id"]')
    
    quantityInput.name = `client_checkout[inventory_movements_attributes][${this.itemIndex}][quantity]`
    quantityInput.max = variant.quantity
    inventoryIdInput.name = `client_checkout[inventory_movements_attributes][${this.itemIndex}][client_inventory_id]`
    inventoryIdInput.value = variant.inventory_id

    // Add to container
    this.itemsContainerTarget.appendChild(row)
    this.itemIndex++
    
    return true
  }

  removeItem(event) {
    const row = event.target.closest('[data-item-row]')
    row.remove()

    // Show empty state if no items
    const remainingItems = this.itemsContainerTarget.querySelectorAll('[data-item-row]')
    if (remainingItems.length === 0 && this.hasEmptyStateTarget) {
      this.emptyStateTarget.style.display = ''
    }
  }

  showError(message) {
    this.hideSuccess()
    this.searchErrorTarget.querySelector('p').textContent = message
    this.searchErrorTarget.classList.remove('hidden')
    
    // Auto-hide error after 3 seconds
    setTimeout(() => {
      this.hideError()
    }, 3000)
  }

  hideError() {
    this.searchErrorTarget.classList.add('hidden')
  }

  showSuccess(message) {
    this.hideError()
    if (this.hasSuccessMessageTarget) {
      this.successMessageTarget.querySelector('span').textContent = message
      this.successMessageTarget.classList.remove('hidden')
      
      // Auto-hide success message after 2 seconds
      setTimeout(() => {
        this.hideSuccess()
      }, 2000)
    }
  }

  hideSuccess() {
    if (this.hasSuccessMessageTarget) {
      this.successMessageTarget.classList.add('hidden')
    }
  }
}

