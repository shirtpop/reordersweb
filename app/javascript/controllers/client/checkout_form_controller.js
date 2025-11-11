import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "skuInput",
    "searchError",
    "successMessage",
    "itemsContainer",
    "emptyState",
    "itemTemplate",
    "submitButton",
    "productSearchModal",
    "productSearchInput",
    "productAutocomplete",
    "selectedProductInfo",
    "selectedProductName",
    "variantsContainer",
    "variantsTableBody",
    "loadingState",
    "modalError",
    "selectAllVariants"
  ]

  connect() {
    this.itemIndex = 0
    this.searchTimeout = null
    this.selectedProduct = null
    this.variants = []
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
      const response = await fetch(`/inventories/product_variants/${encodeURIComponent(sku)}`, {
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

  // Product Search Modal Methods
  openProductSearchModal() {
    this.productSearchModalTarget.classList.remove('hidden')
    // Prevent body scroll
    document.body.style.overflow = 'hidden'
    // Focus on the search input after modal opens
    setTimeout(() => {
      if (this.hasProductSearchInputTarget) {
        this.productSearchInputTarget.focus()
      }
    }, 100)
  }

  closeProductSearchModal(event) {
    // Prevent event from bubbling if called from overlay click
    if (event) {
      event.stopPropagation()
    }
    this.productSearchModalTarget.classList.add('hidden')
    // Restore body scroll
    document.body.style.overflow = ''
    this.resetProductSearch()
  }

  stopPropagation(event) {
    event.stopPropagation()
  }

  resetProductSearch() {
    this.productSearchInputTarget.value = ""
    this.selectedProduct = null
    this.variants = []
    this.hideProductAutocomplete()
    this.hideSelectedProductInfo()
    this.hideVariantsContainer()
    this.hideModalError()
    this.hideLoadingState()
  }

  handleProductSearch(event) {
    clearTimeout(this.searchTimeout)
    const query = event.target.value.trim()

    if (query.length < 3) {
      this.hideProductAutocomplete()
      this.hideModalError()
      return
    }

    this.hideModalError()
    this.searchTimeout = setTimeout(() => {
      this.searchProducts(query)
    }, 300)
  }

  async searchProducts(query) {
    try {
      this.hideModalError()
      const response = await fetch(`/inventories/products.json?q=${encodeURIComponent(query)}`, {
        headers: {
          'Accept': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.content || document.querySelector('[name="csrf-token"]')?.content,
          'X-Requested-With': 'XMLHttpRequest'
        }
      })

      if (!response.ok) {
        const errorText = await response.text()
        console.error('Product search failed:', response.status, errorText)
        throw new Error(`Failed to search products (${response.status})`)
      }

      const data = await response.json()
      console.log('Product search results:', data)
      this.displayProductResults(data.products || [])
    } catch (error) {
      console.error('Product search error:', error)
      this.showModalError(`Failed to search products: ${error.message}`)
    }
  }

  displayProductResults(products) {
    const autocompleteList = this.productAutocompleteTarget.querySelector('ul')
    autocompleteList.innerHTML = ''

    if (products.length === 0) {
      autocompleteList.innerHTML = '<li class="px-4 py-2 text-sm text-gray-500">No products found</li>'
      this.productAutocompleteTarget.classList.remove('hidden')
      return
    }

    products.forEach(product => {
      const li = document.createElement('li')
      li.className = 'px-4 py-2 hover:bg-gray-50 cursor-pointer'
      li.innerHTML = `<div class="text-sm font-medium text-gray-900">${this.escapeHtml(product.name)}</div>`
      li.addEventListener('click', () => this.selectProduct(product))
      autocompleteList.appendChild(li)
    })

    this.productAutocompleteTarget.classList.remove('hidden')
  }

  hideProductAutocomplete() {
    this.productAutocompleteTarget.classList.add('hidden')
  }

  async selectProduct(product) {
    this.selectedProduct = product
    this.hideProductAutocomplete()
    this.showSelectedProductInfo(product)
    this.hideVariantsContainer()
    this.showLoadingState()

    try {
      await this.fetchProductVariants(product.id)
    } catch (error) {
      console.error('Failed to fetch variants:', error)
      this.showModalError('Failed to load product variants. Please try again.')
      this.hideLoadingState()
    }
  }

  async fetchProductVariants(productId) {
    try {
      const response = await fetch(`/inventories/product_variants.json?product_id=${encodeURIComponent(productId)}`, {
        headers: {
          'Accept': 'application/json',
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
        }
      })

      if (!response.ok) {
        throw new Error('Failed to fetch product variants')
      }

      const data = await response.json()
      this.variants = data.product_variants || []
      this.displayVariants(this.variants)
      this.hideLoadingState()
    } catch (error) {
      console.error('Fetch variants failed:', error)
      throw error
    }
  }

  showSelectedProductInfo(product) {
    this.selectedProductNameTarget.textContent = product.name
    this.selectedProductInfoTarget.classList.remove('hidden')
  }

  hideSelectedProductInfo() {
    this.selectedProductInfoTarget.classList.add('hidden')
  }

  displayVariants(variants) {
    const tbody = this.variantsTableBodyTarget
    tbody.innerHTML = ''

    if (variants.length === 0) {
      tbody.innerHTML = '<tr><td colspan="5" class="px-4 py-4 text-center text-sm text-gray-500">No variants available</td></tr>'
      this.variantsContainerTarget.classList.remove('hidden')
      return
    }

    variants.forEach((variant, index) => {
      const tr = document.createElement('tr')
      tr.className = variant.quantity > 0 ? '' : 'opacity-50'
      tr.dataset.variantIndex = index

      const canSelect = variant.inventory_id && variant.quantity > 0

      tr.innerHTML = `
        <td class="px-4 py-3 whitespace-nowrap">
          <input type="checkbox" 
                 class="variant-checkbox rounded border-gray-300 text-pink-600 focus:ring-pink-500"
                 data-variant-index="${index}"
                 ${canSelect ? '' : 'disabled'}>
        </td>
        <td class="px-4 py-3 whitespace-nowrap text-sm text-gray-900">${this.escapeHtml(variant.sku || 'N/A')}</td>
        <td class="px-4 py-3 whitespace-nowrap text-sm text-gray-900">${this.escapeHtml(variant.color || 'N/A')}</td>
        <td class="px-4 py-3 whitespace-nowrap text-sm text-gray-900">${this.escapeHtml(variant.size || 'N/A')}</td>
        <td class="px-4 py-3 whitespace-nowrap text-sm ${variant.quantity > 0 ? 'text-gray-900' : 'text-red-600'}">
          ${variant.quantity > 0 ? `${variant.quantity} units` : 'Out of stock'}
        </td>
      `

      tbody.appendChild(tr)
    })

    this.variantsContainerTarget.classList.remove('hidden')
  }

  hideVariantsContainer() {
    this.variantsContainerTarget.classList.add('hidden')
  }

  showLoadingState() {
    this.loadingStateTarget.classList.remove('hidden')
  }

  hideLoadingState() {
    this.loadingStateTarget.classList.add('hidden')
  }

  showModalError(message) {
    const errorElement = this.modalErrorTarget.querySelector('p')
    errorElement.textContent = message
    this.modalErrorTarget.classList.remove('hidden')
  }

  hideModalError() {
    this.modalErrorTarget.classList.add('hidden')
  }

  toggleAllVariants(event) {
    const isChecked = event.target.checked
    const checkboxes = this.variantsTableBodyTarget.querySelectorAll('.variant-checkbox:not(:disabled)')
    checkboxes.forEach(checkbox => {
      checkbox.checked = isChecked
    })
  }

  addSelectedVariants() {
    const checkboxes = this.variantsTableBodyTarget.querySelectorAll('.variant-checkbox:checked:not(:disabled)')
    
    if (checkboxes.length === 0) {
      this.showModalError('Please select at least one variant to add.')
      return
    }

    let addedCount = 0
    let skippedCount = 0

    checkboxes.forEach(checkbox => {
      const variantIndex = parseInt(checkbox.dataset.variantIndex)
      const variant = this.variants[variantIndex]

      if (variant && variant.inventory_id && variant.quantity > 0) {
        const success = this.addItem(variant)
        if (success) {
          addedCount++
        } else {
          skippedCount++
        }
      }
    })

    if (addedCount > 0) {
      this.showSuccess(`${addedCount} variant(s) added successfully`)
      this.closeProductSearchModal()
    }

    if (skippedCount > 0) {
      this.showModalError(`${skippedCount} variant(s) could not be added (may already be in list or out of stock)`)
    }
  }

  escapeHtml(text) {
    const div = document.createElement('div')
    div.textContent = text
    return div.innerHTML
  }
}

