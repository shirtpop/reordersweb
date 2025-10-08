// app/javascript/controllers/client/product_autocomplete_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["nameField", "productIdField", "dropdown", "results"]
  static values = { 
    searchUrl: String,
    minLength: { type: Number, default: 3 }
  }

  connect() {
    this.searchUrlValue = "/inventories/products/admin_products"
    this.searchTimeout = null
    this.selectedIndex = -1
    this.results = []
    
    // Hide dropdown when clicking outside
    document.addEventListener('click', this.hideDropdown.bind(this))
  }

  disconnect() {
    document.removeEventListener('click', this.hideDropdown.bind(this))
    if (this.searchTimeout) {
      clearTimeout(this.searchTimeout)
    }
  }

  search(event) {
    const query = event.target.value.trim()
    
    if (this.searchTimeout) {
      clearTimeout(this.searchTimeout)
    }

    if (query.length < this.minLengthValue) {
      this.hideDropdown()
      // Clear the product_id when user starts typing something new
      if (this.hasProductIdFieldTarget) {
        this.productIdFieldTarget.value = ""
      }
      return
    }

    // Debounce the search
    this.searchTimeout = setTimeout(() => {
      this.performSearch(query)
    }, 300)
  }

  handleKeyup(event) {
    if (event.key === 'ArrowDown') {
      event.preventDefault()
      this.navigateResults(1)
    } else if (event.key === 'ArrowUp') {
      event.preventDefault()
      this.navigateResults(-1)
    } else if (event.key === 'Enter') {
      event.preventDefault()
      this.selectCurrentResult()
    } else if (event.key === 'Escape') {
      this.hideDropdown()
    }
  }

  async performSearch(query) {
    try {
      const response = await fetch(`${this.searchUrlValue}?q=${encodeURIComponent(query)}`, {
        headers: {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest'
        }
      })

      if (!response.ok) {
        throw new Error('Search failed')
      }

      const data = await response.json()
      this.results = data.products || []
      this.displayResults()
    } catch (error) {
      console.error('Search error:', error)
      this.hideDropdown()
    }
  }

  displayResults() {
    if (this.results.length === 0) {
      this.hideDropdown()
      return
    }

    const resultsHtml = this.results.map((product, index) => `
      <div class="px-4 py-2 hover:bg-gray-100 cursor-pointer border-b border-gray-100 last:border-b-0 ${
        index === this.selectedIndex ? 'bg-gray-100' : ''
      }" 
           data-product-autocomplete-target="resultItem"
           data-action="click->product-autocomplete#selectProduct"
           data-product-id="${product.id}"
           data-product-name="${product.name}"
           data-product-description="${product.description || ''}">
        <div class="font-medium text-gray-900">${this.escapeHtml(product.name)}</div>
        ${product.description ? `<div class="text-sm text-gray-600 mt-1">${this.escapeHtml(product.description.substring(0, 100))}${product.description.length > 100 ? '...' : ''}</div>` : ''}
      </div>
    `).join('')

    this.resultsTarget.innerHTML = resultsHtml
    this.showDropdown()
  }

  navigateResults(direction) {
    if (this.results.length === 0) return

    this.selectedIndex += direction
    
    if (this.selectedIndex < 0) {
      this.selectedIndex = this.results.length - 1
    } else if (this.selectedIndex >= this.results.length) {
      this.selectedIndex = 0
    }

    // Update visual selection
    this.resultsTarget.querySelectorAll('[data-product-autocomplete-target="resultItem"]').forEach((item, index) => {
      item.classList.toggle('bg-gray-100', index === this.selectedIndex)
    })
  }

  selectCurrentResult() {
    if (this.selectedIndex >= 0 && this.selectedIndex < this.results.length) {
      const product = this.results[this.selectedIndex]
      this.selectProductFromData(product)
    }
  }

  selectProduct(event) {
    const productId = event.currentTarget.dataset.productId
    const productName = event.currentTarget.dataset.productName
    const productDescription = event.currentTarget.dataset.productDescription

    this.selectProductFromData({
      id: productId,
      name: productName,
      description: productDescription
    })
  }

  selectProductFromData(product) {
    // Update name field
    this.nameFieldTarget.value = product.name
    
    // Update hidden product_id field
    if (this.hasProductIdFieldTarget) {
      this.productIdFieldTarget.value = product.id
    }
    
    // Update description field
    if (product.description) {
      // Try multiple approaches to set the rich text content
      this.setDescriptionContent(product.description)
    }

    this.hideDropdown()
  }

  setDescriptionContent(description) {
    console.log('Setting description content:', description)
    
    // Method 1: Find the Trix editor by the specific ID
    const trixEditor = document.getElementById('client_product_description')
    if (trixEditor && trixEditor.editor) {
      console.log('Found Trix editor by ID, setting content')
      trixEditor.editor.loadHTML(description)
      trixEditor.dispatchEvent(new Event('change', { bubbles: true }))
      return
    }
    
    // Method 2: Find the hidden input field that stores the actual value
    const hiddenInput = document.getElementById('client_product_description_trix_input_client_product')
    if (hiddenInput) {
      console.log('Found hidden input field, setting value directly')
      hiddenInput.value = description
      hiddenInput.dispatchEvent(new Event('change', { bubbles: true }))
      
      // Also try to update the Trix editor if it exists
      const trixEditorDelayed = document.getElementById('client_product_description')
      if (trixEditorDelayed && trixEditorDelayed.editor) {
        console.log('Also updating Trix editor')
        trixEditorDelayed.editor.loadHTML(description)
      }
      return
    }
    
    // Method 3: Wait a bit for Trix to initialize and try again
    setTimeout(() => {
      const trixEditorDelayed = document.getElementById('client_product_description')
      if (trixEditorDelayed && trixEditorDelayed.editor) {
        console.log('Found Trix editor after delay, setting content')
        trixEditorDelayed.editor.loadHTML(description)
        trixEditorDelayed.dispatchEvent(new Event('change', { bubbles: true }))
        return
      }
      
      const hiddenInputDelayed = document.getElementById('client_product_description_trix_input_client_product')
      if (hiddenInputDelayed) {
        console.log('Found hidden input after delay, setting value')
        hiddenInputDelayed.value = description
        hiddenInputDelayed.dispatchEvent(new Event('change', { bubbles: true }))
        return
      }
      
      console.log('Could not find either Trix editor or hidden input')
    }, 300)
  }

  showDropdown() {
    this.dropdownTarget.classList.remove('hidden')
    this.dropdownTarget.classList.add('block')
    this.selectedIndex = -1
  }

  hideDropdown(event) {
    // Don't hide if clicking on the autocomplete elements
    if (event && (
      this.element.contains(event.target) || 
      this.dropdownTarget.contains(event.target)
    )) {
      return
    }
    
    this.dropdownTarget.classList.add('hidden')
    this.dropdownTarget.classList.remove('block')
    this.selectedIndex = -1
  }

  escapeHtml(text) {
    const div = document.createElement('div')
    div.textContent = text
    return div.innerHTML
  }
}