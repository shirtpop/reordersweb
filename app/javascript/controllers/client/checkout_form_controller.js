import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "skuInput",
    "searchError",
    "successMessage",
    "productSearchModal",
    "productSearchInput",
    "productAutocomplete",
    "selectedProductInfo",
    "selectedProductName",
    "variantsContainer",
    "variantsTableBody",
    "loadingState",
    "modalError",
    "selectAllVariants",
  ]

  connect() {
    this.searchTimeout = null
    this.selectedProduct = null
    this.variants = []
  }

  preventSubmit(event) {
    if (document.activeElement === this.skuInputTarget) {
      event.preventDefault()
      return false
    }
  }

  handleSkuSearch(event) {
    if (event.key === "Enter" || event.keyCode === 13) {
      event.preventDefault()
      event.stopPropagation()
      this.searchSku()
    }
  }

  searchSkuButton(event) {
    event.preventDefault()
    event.stopPropagation()
    this.searchSku()
  }

  async searchSku() {
    const sku = this.skuInputTarget.value.trim()

    if (!sku) {
      this.showError("Please enter a SKU")
      return
    }

    this.hideError()
    this.skuInputTarget.disabled = true

    try {
      const response = await fetch(`/inventories/product_variants/${encodeURIComponent(sku)}`, {
        headers: {
          "Accept": "application/json",
          "X-CSRF-Token": document.querySelector("[name='csrf-token']").content
        }
      })

      if (!response.ok) throw new Error("Product variant not found")

      const variant = await response.json()

      if (!variant.inventory_id || variant.quantity <= 0) {
        this.showError("This item is out of stock")
        return
      }

      const added = await this.addToBasket(variant.inventory_id, 1)
      if (added) {
        this.skuInputTarget.value = ""
        this.showSuccess(`${variant.product_name} (${variant.sku}) added to basket`)
      }
    } catch (error) {
      this.showError(error.message || "Product not found. Please check the SKU and try again.")
    } finally {
      this.skuInputTarget.disabled = false
      this.skuInputTarget.focus()
    }
  }

  async addToBasket(inventoryId, quantity) {
    try {
      const response = await fetch(
        `/inventories/checkouts/items/${inventoryId}`,
        {
          method: "POST",
          headers: {
            "Accept": "text/vnd.turbo-stream.html",
            "Content-Type": "application/json",
            "X-CSRF-Token": document.querySelector("[name='csrf-token']").content
          },
          body: JSON.stringify({ client_inventory_id: inventoryId, quantity })
        }
      )

      if (!response.ok) throw new Error("Failed to add item to basket")

      const html = await response.text()
      window.Turbo.renderStreamMessage(html)
      return true
    } catch (error) {
      this.showError(error.message || "Failed to add item to basket")
      return false
    }
  }

  showError(message) {
    this.hideSuccess()
    this.searchErrorTarget.querySelector("p").textContent = message
    this.searchErrorTarget.classList.remove("hidden")
    setTimeout(() => this.hideError(), 3000)
  }

  hideError() {
    this.searchErrorTarget.classList.add("hidden")
  }

  showSuccess(message) {
    this.hideError()
    if (this.hasSuccessMessageTarget) {
      this.successMessageTarget.querySelector("span").textContent = message
      this.successMessageTarget.classList.remove("hidden")
      setTimeout(() => this.hideSuccess(), 2000)
    }
  }

  hideSuccess() {
    if (this.hasSuccessMessageTarget) {
      this.successMessageTarget.classList.add("hidden")
    }
  }

  // ── Product Search Modal ────────────────────────────────────────────────────

  openProductSearchModal() {
    this.productSearchModalTarget.classList.remove("hidden")
    document.body.style.overflow = "hidden"
    setTimeout(() => {
      if (this.hasProductSearchInputTarget) this.productSearchInputTarget.focus()
    }, 100)
  }

  closeProductSearchModal(event) {
    if (event) event.stopPropagation()
    this.productSearchModalTarget.classList.add("hidden")
    document.body.style.overflow = ""
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
    this.searchTimeout = setTimeout(() => this.searchProducts(query), 300)
  }

  async searchProducts(query) {
    try {
      this.hideModalError()
      const response = await fetch(`/inventories/products.json?q=${encodeURIComponent(query)}`, {
        headers: {
          "Accept": "application/json",
          "X-CSRF-Token": document.querySelector("[name='csrf-token']").content,
          "X-Requested-With": "XMLHttpRequest"
        }
      })
      if (!response.ok) throw new Error(`Failed to search products (${response.status})`)
      const data = await response.json()
      this.displayProductResults(data.products || [])
    } catch (error) {
      this.showModalError(`Failed to search products: ${error.message}`)
    }
  }

  displayProductResults(products) {
    const list = this.productAutocompleteTarget.querySelector("ul")
    list.innerHTML = ""
    if (products.length === 0) {
      list.innerHTML = '<li class="px-4 py-2 text-sm text-gray-500">No products found</li>'
    } else {
      products.forEach(product => {
        const li = document.createElement("li")
        li.className = "px-4 py-2 hover:bg-gray-50 cursor-pointer"
        li.innerHTML = `<div class="text-sm font-medium text-gray-900">${this.escapeHtml(product.name)}</div>`
        li.addEventListener("click", () => this.selectProduct(product))
        list.appendChild(li)
      })
    }
    this.productAutocompleteTarget.classList.remove("hidden")
  }

  hideProductAutocomplete() {
    this.productAutocompleteTarget.classList.add("hidden")
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
      this.showModalError("Failed to load product variants. Please try again.")
      this.hideLoadingState()
    }
  }

  async fetchProductVariants(productId) {
    const response = await fetch(`/inventories/product_variants.json?product_id=${encodeURIComponent(productId)}`, {
      headers: {
        "Accept": "application/json",
        "X-CSRF-Token": document.querySelector("[name='csrf-token']").content
      }
    })
    if (!response.ok) throw new Error("Failed to fetch product variants")
    const data = await response.json()
    this.variants = data.product_variants || []
    this.displayVariants(this.variants)
    this.hideLoadingState()
  }

  showSelectedProductInfo(product) {
    this.selectedProductNameTarget.textContent = product.name
    this.selectedProductInfoTarget.classList.remove("hidden")
  }

  hideSelectedProductInfo() {
    this.selectedProductInfoTarget.classList.add("hidden")
  }

  displayVariants(variants) {
    const tbody = this.variantsTableBodyTarget
    tbody.innerHTML = ""
    if (variants.length === 0) {
      tbody.innerHTML = '<tr><td colspan="5" class="px-4 py-4 text-center text-sm text-gray-500">No variants available</td></tr>'
      this.variantsContainerTarget.classList.remove("hidden")
      return
    }
    variants.forEach((variant, index) => {
      const canSelect = variant.inventory_id && variant.quantity > 0
      const tr = document.createElement("tr")
      tr.className = canSelect ? "" : "opacity-50"
      tr.dataset.variantIndex = index
      tr.innerHTML = `
        <td class="px-4 py-3 whitespace-nowrap">
          <input type="checkbox"
                 class="variant-checkbox rounded border-gray-300 text-pink-600 focus:ring-pink-500"
                 data-variant-index="${index}"
                 ${canSelect ? "" : "disabled"}>
        </td>
        <td class="px-4 py-3 whitespace-nowrap text-sm text-gray-900">${this.escapeHtml(variant.sku || "N/A")}</td>
        <td class="px-4 py-3 whitespace-nowrap text-sm text-gray-900">${this.escapeHtml(variant.color || "N/A")}</td>
        <td class="px-4 py-3 whitespace-nowrap text-sm text-gray-900">${this.escapeHtml(variant.size || "N/A")}</td>
        <td class="px-4 py-3 whitespace-nowrap text-sm ${canSelect ? "text-gray-900" : "text-red-600"}">
          ${canSelect ? `${variant.quantity} units` : "Out of stock"}
        </td>
      `
      tbody.appendChild(tr)
    })
    this.variantsContainerTarget.classList.remove("hidden")
  }

  hideVariantsContainer() {
    this.variantsContainerTarget.classList.add("hidden")
  }

  showLoadingState() {
    this.loadingStateTarget.classList.remove("hidden")
  }

  hideLoadingState() {
    this.loadingStateTarget.classList.add("hidden")
  }

  showModalError(message) {
    this.modalErrorTarget.querySelector("p").textContent = message
    this.modalErrorTarget.classList.remove("hidden")
  }

  hideModalError() {
    this.modalErrorTarget.classList.add("hidden")
  }

  toggleAllVariants(event) {
    const checkboxes = this.variantsTableBodyTarget.querySelectorAll(".variant-checkbox:not(:disabled)")
    checkboxes.forEach(cb => { cb.checked = event.target.checked })
  }

  async addSelectedVariants() {
    const checkboxes = this.variantsTableBodyTarget.querySelectorAll(".variant-checkbox:checked:not(:disabled)")
    if (checkboxes.length === 0) {
      this.showModalError("Please select at least one variant to add.")
      return
    }
    let addedCount = 0
    for (const checkbox of checkboxes) {
      const variant = this.variants[parseInt(checkbox.dataset.variantIndex)]
      if (variant?.inventory_id && variant.quantity > 0) {
        const ok = await this.addToBasket(variant.inventory_id, 1)
        if (ok) addedCount++
      }
    }
    if (addedCount > 0) {
      this.showSuccess(`${addedCount} variant(s) added to basket`)
      this.closeProductSearchModal()
    }
  }

  escapeHtml(text) {
    const div = document.createElement("div")
    div.textContent = text
    return div.innerHTML
  }
}
