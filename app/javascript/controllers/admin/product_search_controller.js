// app/javascript/controllers/product_search_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["searchInput", "resultsDropdown", "resultsList", "selectedProducts", "emptyState", "hiddenInput"]
  static values = { url: String }

  connect() {
    this.selectedProductIds = new Set()
    this.searchTimeout = null
    
    // Initialize with existing products
    this.initializeExistingProducts()
    
    // Close dropdown when clicking outside
    this.boundCloseDropdown = this.closeDropdown.bind(this)
    document.addEventListener('click', this.boundCloseDropdown)
  }

  disconnect() {
    if (this.searchTimeout) {
      clearTimeout(this.searchTimeout)
    }
    document.removeEventListener('click', this.boundCloseDropdown)
  }

  initializeExistingProducts() {
    // Get existing product IDs from hidden inputs
    const existingInputs = this.selectedProductsTarget.querySelectorAll('input[type="hidden"]')
    existingInputs.forEach(input => {
      if (input.value) {
        this.selectedProductIds.add(parseInt(input.value))
      }
    })
    this.updateEmptyState()
  }

  search() {
    const query = this.searchInputTarget.value.trim()
    
    // Clear previous timeout
    if (this.searchTimeout) {
      clearTimeout(this.searchTimeout)
    }

    if (query.length < 2) {
      this.hideDropdown()
      return
    }

    // Debounce search
    this.searchTimeout = setTimeout(() => {
      this.performSearch(query)
    }, 300)
  }

  async performSearch(query) {
    try {
      const response = await fetch(`${this.urlValue}?q=${encodeURIComponent(query)}`, {
        headers: {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest'
        }
      })

      if (response.ok) {
        const data = await response.json()
        this.displayResults(data.products)
      }
    } catch (error) {
      console.error('Search failed:', error)
    }
  }

  displayResults(products) {
    this.resultsListTarget.innerHTML = ''

    if (products.length === 0) {
      this.resultsListTarget.innerHTML = `
        <div class="px-4 py-3 text-gray-500 dark:text-gray-400 text-center">
          No products found
        </div>
      `
    } else {
      console.log('Products found:', products)
      products.forEach(product => {
        const isSelected = this.selectedProductIds.has(product.id)
        const resultElement = document.createElement('div')
        resultElement.className = `px-4 py-3 cursor-pointer hover:bg-gray-100 dark:hover:bg-gray-600 border-b border-gray-200 dark:border-gray-600 last:border-b-0 ${isSelected ? 'bg-gray-100 dark:bg-gray-600 opacity-50' : ''}`
        resultElement.innerHTML = `
          <div class="flex items-center justify-between">
            <div>
              <div class="font-medium text-gray-900 dark:text-white">${this.escapeHtml(product.name)}</div>
              ${product.color_names ? `<div class="text-sm text-gray-500 dark:text-gray-400">Colors: ${this.escapeHtml(product.color_names)}</div>` : ''}
            </div>
            ${isSelected ? '<span class="text-sm text-green-600 dark:text-green-400 font-medium">Added</span>' : ''}
          </div>
        `
        
        if (!isSelected) {
          resultElement.addEventListener('click', () => this.selectProduct(product))
        }
        
        this.resultsListTarget.appendChild(resultElement)
      })
    }

    this.showDropdown()
  }

  selectProduct(product) {
    if (this.selectedProductIds.has(product.id)) {
      return
    }

    this.selectedProductIds.add(product.id)
    this.addProductToList(product)
    this.clearSearch()
    this.hideDropdown()
    this.updateEmptyState()
  }

  addProductToList(product) {
    const productElement = document.createElement('div')
    productElement.className = 'flex items-center justify-between p-4 bg-gray-50 dark:bg-gray-700 rounded-lg border border-gray-200 dark:border-gray-600'
    productElement.dataset.productId = product.id
    productElement.innerHTML = `
      <div class="flex-1">
        <h4 class="font-medium text-gray-900 dark:text-white">${this.escapeHtml(product.name)}</h4>
        ${product.color_names ? `<p class="text-sm text-gray-500 dark:text-gray-400">Colors: ${this.escapeHtml(product.color_names)}</p>` : ''}
      </div>
      <button type="button" 
              class="ml-4 text-red-600 hover:text-red-700 dark:text-red-400 dark:hover:text-red-300"
              data-action="click->product-search#removeProduct"
              data-product-id="${product.id}">
        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path>
        </svg>
      </button>
      <input type="hidden" name="project[product_ids][]" value="${product.id}" data-product-search-target="hiddenInput">
    `

    this.selectedProductsTarget.appendChild(productElement)
  }

  removeProduct(event) {
    const productId = parseInt(event.currentTarget.dataset.productId)
    const productElement = event.currentTarget.closest('[data-product-id]')
    
    this.selectedProductIds.delete(productId)
    productElement.remove()
    this.updateEmptyState()
  }

  handleKeydown(event) {
    if (event.key === 'Escape') {
      this.hideDropdown()
      this.searchInputTarget.blur()
    }
  }

  clearSearch() {
    this.searchInputTarget.value = ''
  }

  showDropdown() {
    this.resultsDropdownTarget.classList.remove('hidden')
  }

  hideDropdown() {
    this.resultsDropdownTarget.classList.add('hidden')
  }

  closeDropdown(event) {
    if (!this.element.contains(event.target)) {
      this.hideDropdown()
    }
  }

  updateEmptyState() {
    const hasProducts = this.selectedProductsTarget.children.length > 0
    if (hasProducts) {
      this.emptyStateTarget.classList.add('hidden')
    } else {
      this.emptyStateTarget.classList.remove('hidden')
    }
  }

  escapeHtml(text) {
    const div = document.createElement('div')
    div.textContent = text
    return div.innerHTML
  }
}