import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "searchInput", "results", "resultsList"]

  connect() {
    this.debounceTimer = null
    this.targetProductSearch = null
  }

  disconnect() {
    if (this.debounceTimer) clearTimeout(this.debounceTimer)
  }

  open(event) {
    // Find the product-search controller that triggered this
    const catalogSection = event.currentTarget.closest('[data-controller*="product-search"]')
    if (catalogSection) {
      this.targetProductSearch = this.application.getControllerForElementAndIdentifier(catalogSection, "product-search")
    }

    if (!this.hasModalTarget) {
      this.createModal()
    }
    this.modalTarget.classList.remove("hidden")
    // Focus the search input after showing
    setTimeout(() => {
      if (this.hasSearchInputTarget) this.searchInputTarget.focus()
    }, 100)
  }

  close() {
    if (this.hasModalTarget) {
      this.modalTarget.classList.add("hidden")
    }
    this.targetProductSearch = null
  }

  createModal() {
    const modal = document.createElement("div")
    modal.dataset.copyProductsTarget = "modal"
    modal.className = "hidden fixed inset-0 z-50 flex items-center justify-center bg-black/50"
    modal.innerHTML = `
      <div class="bg-white dark:bg-gray-800 rounded-lg shadow-xl w-full max-w-md mx-4 p-6">
        <div class="flex items-center justify-between mb-4">
          <h3 class="text-lg font-medium text-gray-900 dark:text-white">Copy Products from Client</h3>
          <button type="button" data-action="click->copy-products#close" class="text-gray-400 hover:text-gray-500">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
            </svg>
          </button>
        </div>
        <div class="relative">
          <input type="text"
                 data-copy-products-target="searchInput"
                 data-action="input->copy-products#searchClients"
                 placeholder="Search client by name..."
                 class="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:border-gray-600 dark:text-white dark:placeholder-gray-400">
          <div data-copy-products-target="results" class="hidden absolute z-10 w-full mt-1 bg-white dark:bg-gray-800 border border-gray-300 dark:border-gray-600 rounded-md shadow-lg max-h-60 overflow-y-auto">
            <div data-copy-products-target="resultsList"></div>
          </div>
        </div>
        <p class="mt-3 text-xs text-gray-500 dark:text-gray-400">Select a client to copy their product assignments into this catalog.</p>
      </div>
    `
    this.element.appendChild(modal)
  }

  searchClients() {
    const query = this.searchInputTarget.value.trim()
    if (this.debounceTimer) clearTimeout(this.debounceTimer)

    if (query.length < 2) {
      this.resultsTarget.classList.add("hidden")
      return
    }

    this.debounceTimer = setTimeout(() => this.performClientSearch(query), 300)
  }

  async performClientSearch(query) {
    try {
      const response = await fetch(`/admin/clients?q=${encodeURIComponent(query)}`, {
        headers: { "Accept": "application/json", "X-Requested-With": "XMLHttpRequest" }
      })

      if (response.ok) {
        const data = await response.json()
        this.displayClientResults(data.clients || [])
      }
    } catch (error) {
      console.error("Client search failed:", error)
    }
  }

  displayClientResults(clients) {
    if (clients.length === 0) {
      this.resultsListTarget.innerHTML = `
        <div class="px-4 py-3 text-center text-sm text-gray-500 dark:text-gray-400">No clients found</div>
      `
    } else {
      this.resultsListTarget.innerHTML = clients.map(client => `
        <div class="px-4 py-3 cursor-pointer hover:bg-gray-100 dark:hover:bg-gray-600 border-b border-gray-200 dark:border-gray-600 last:border-b-0"
             data-action="click->copy-products#selectClient"
             data-client-id="${client.id}"
             data-client-name="${this.escapeHtml(client.company_name)}">
          <p class="text-sm font-medium text-gray-900 dark:text-white">${this.escapeHtml(client.company_name)}</p>
          <p class="text-xs text-gray-500 dark:text-gray-400">${this.escapeHtml(client.personal_name)}</p>
        </div>
      `).join("")
    }
    this.resultsTarget.classList.remove("hidden")
  }

  async selectClient(event) {
    const clientId = event.currentTarget.dataset.clientId
    const clientName = event.currentTarget.dataset.clientName

    if (!confirm(`Copy all products from "${clientName}" into this catalog?`)) return

    try {
      const response = await fetch(`/admin/clients/${clientId}/product_assignments`, {
        headers: { "Accept": "application/json", "X-Requested-With": "XMLHttpRequest" }
      })

      if (response.ok) {
        const data = await response.json()
        this.applyProducts(data.products)
        this.close()
      }
    } catch (error) {
      console.error("Failed to fetch products:", error)
    }
  }

  applyProducts(products) {
    if (!this.targetProductSearch) return

    products.forEach(product => {
      if (!this.targetProductSearch.selectedProductIds.has(product.id)) {
        this.targetProductSearch.selectProduct(product)
      }
    })
  }

  escapeHtml(text) {
    const div = document.createElement("div")
    div.textContent = text
    return div.innerHTML
  }
}
