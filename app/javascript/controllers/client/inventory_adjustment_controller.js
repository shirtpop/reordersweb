import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "searchInput",
    "searchResults",
    "productTable",
    "productName",
    "adjustmentForm"
  ]

  static values = {
    searchUrl: String
  }

  connect() {
    this.timeout = null
  }

  search() {
    clearTimeout(this.timeout)
    
    const query = this.searchInputTarget.value.trim()
    
    if (query.length < 2) {
      this.searchResultsTarget.innerHTML = ""
      this.searchResultsTarget.classList.add("hidden")
      return
    }

    this.timeout = setTimeout(() => {
      this.performSearch(query)
    }, 300)
  }

  async performSearch(query) {
    try {
      const response = await fetch(`${this.searchUrlValue}?q=${encodeURIComponent(query)}`, {
        headers: {
          "Accept": "application/json"
        }
      })
      
      const products = await response.json()
      this.displaySearchResults(products)
    } catch (error) {
      console.error("Search failed:", error)
    }
  }

  displaySearchResults(products) {
    if (products.length === 0) {
      this.searchResultsTarget.innerHTML = `
        <div class="p-4 text-sm text-gray-500">
          No products found
        </div>
      `
      this.searchResultsTarget.classList.remove("hidden")
      return
    }

    const resultsHtml = products.map(product => `
      <button type="button" 
              class="w-full text-left px-4 py-3 hover:bg-gray-100 border-b border-gray-200 last:border-b-0"
              data-action="click->inventory-adjustment#selectProduct"
              data-product-id="${product.id}"
              data-product-name="${product.name}"
              data-product-variants='${JSON.stringify(product.variants)}'>
        <div class="font-medium text-gray-900">${product.name}</div>
        <div class="text-sm text-gray-500">${product.variant_count} variants</div>
      </button>
    `).join("")

    this.searchResultsTarget.innerHTML = resultsHtml
    this.searchResultsTarget.classList.remove("hidden")
  }

  selectProduct(event) {
    const button = event.currentTarget
    const productId = button.dataset.productId
    const productName = button.dataset.productName
    const variants = JSON.parse(button.dataset.productVariants)

    // Hide search results
    this.searchResultsTarget.classList.add("hidden")
    
    // Update product name
    this.productNameTarget.textContent = productName

    // Build and display the variants table
    this.buildVariantsTable(variants, productId)
    
    // Show the table
    this.productTableTarget.classList.remove("hidden")
  }

  buildVariantsTable(variants, productId) {
    // Extract unique colors and sizes
    const colors = [...new Set(variants.map(v => v.color))].sort()
    const sizes = [...new Set(variants.map(v => v.size))].sort()

    // Create a map for quick lookup: color_size -> variant
    const variantMap = {}
    variants.forEach(variant => {
      const key = `${variant.color}_${variant.size}`
      variantMap[key] = variant
    })

    // Build table header
    let headerHtml = `
      <thead class="bg-gray-50">
        <tr>
          <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider sticky left-0 bg-gray-50">
            Color
          </th>
          ${sizes.map(size => `
            <th class="px-4 py-3 text-center text-xs font-medium text-gray-500 uppercase tracking-wider">
              ${size}
            </th>
          `).join("")}
        </tr>
      </thead>
    `

    // Build table body
    let bodyHtml = `<tbody class="bg-white divide-y divide-gray-200">`
    
    colors.forEach(color => {
      bodyHtml += `<tr>`
      bodyHtml += `
        <td class="px-4 py-3 text-sm font-medium text-gray-900 sticky left-0 bg-white">
          ${color}
        </td>
      `
      
      sizes.forEach(size => {
        const key = `${color}_${size}`
        const variant = variantMap[key]
        
        if (variant) {
          bodyHtml += `
            <td class="px-4 py-3 text-center">
              <div class="space-y-2">
                <div class="text-xs text-gray-500 font-mono">
                  ${variant.sku || 'N/A'}
                </div>
                <input type="number" 
                       name="adjustments[product_variants][][product_variant_quantity]"
                       data-variant-id="${variant.id}"
                       min="0"
                       class="w-20 px-2 py-1 text-sm border border-gray-300 rounded-md focus:ring-pink-500 focus:border-pink-500"
                       placeholder="0">
                <input type="hidden" name="adjustments[product_variants][][product_variant_id]" value="${variant.id}">
              </div>
            </td>
          `
        } else {
          bodyHtml += `
            <td class="px-4 py-3 text-center">
              <span class="text-gray-300">—</span>
            </td>
          `
        }
      })
      
      bodyHtml += `</tr>`
    })
    
    bodyHtml += `</tbody>`

    // Update the table
    const tableHtml = `
      <div class="overflow-x-auto">
        <table class="min-w-full divide-y divide-gray-200">
          ${headerHtml}
          ${bodyHtml}
        </table>
      </div>
    `
    
    this.adjustmentFormTarget.innerHTML = tableHtml
  }

  clearSearch() {
    this.searchInputTarget.value = ""
    this.searchResultsTarget.innerHTML = ""
    this.searchResultsTarget.classList.add("hidden")
    this.productTableTarget.classList.add("hidden")
  }
}

