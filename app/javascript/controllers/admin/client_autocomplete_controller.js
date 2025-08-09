// app/javascript/controllers/client_autocomplete_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "input", "results", "resultsList", "hiddenField"]
  static values = { url: String }

  connect() {
    // Set default URL if not provided
    if (!this.urlValue) {
      this.urlValue = "/admin/clients/search"
    }
    
    this.debounceTimer = null
    this.isMouseOverResults = false
    
    // Bind methods to preserve context
    this.boundHandleDocumentClick = this.handleDocumentClick.bind(this)
  }

  disconnect() {
    this.clearDebounceTimer()
    document.removeEventListener("click", this.boundHandleDocumentClick)
  }

  search(event) {
    const query = event.target.value.trim()
    
    this.clearDebounceTimer()
    
    if (query.length < 2) {
      this.hideResults()
      return
    }

    // Debounce the search to avoid too many requests
    this.debounceTimer = setTimeout(() => {
      this.performSearch(query)
    }, 300)
  }

  async performSearch(query) {
    try {
      const params = new URLSearchParams({ q: query })
      const response = await fetch(`${this.urlValue}?${params}`, {
        headers: {
          "Accept": "application/json",
          "X-Requested-With": "XMLHttpRequest"
        }
      })

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }

      const data = await response.json()
      this.displayResults(data.clients || [])
    } catch (error) {
      console.error("Error fetching clients:", error)
      this.displayError()
    }
  }

  displayResults(clients) {
    if (clients.length === 0) {
      this.displayNoResults()
      return
    }

    const resultsHTML = clients.map(client => `
      <div class="px-4 py-2 cursor-pointer hover:bg-gray-100 dark:hover:bg-gray-600 border-b border-gray-200 dark:border-gray-600 last:border-b-0"
           data-client-id="${client.id}"
           data-client-name="${client.name}"
           data-action="mousedown->client-autocomplete#selectClient mouseenter->client-autocomplete#handleMouseEnter mouseleave->client-autocomplete#handleMouseLeave">
        <div class="flex items-center">
          <div class="flex-1">
            <p class="text-sm font-medium text-gray-900 dark:text-white">
              ${this.escapeHtml(client.name)}
            </p>
            <p class="text-xs text-gray-500 dark:text-gray-400">
              ${this.escapeHtml(client.email || 'No email')}
            </p>
          </div>
          ${client.company ? `
            <div class="text-xs text-gray-400 dark:text-gray-500">
              ${this.escapeHtml(client.company)}
            </div>
          ` : ''}
        </div>
      </div>
    `).join('')

    this.resultsListTarget.innerHTML = resultsHTML
    this.showResults()
  }

  displayNoResults() {
    this.resultsListTarget.innerHTML = `
      <div class="px-4 py-3 text-center text-sm text-gray-500 dark:text-gray-400">
        No clients found
      </div>
    `
    this.showResults()
  }

  displayError() {
    this.resultsListTarget.innerHTML = `
      <div class="px-4 py-3 text-center text-sm text-red-500 dark:text-red-400">
        Error loading clients. Please try again.
      </div>
    `
    this.showResults()
  }

  selectClient(event) {
    event.preventDefault()
    const clientId = event.currentTarget.dataset.clientId
    const clientName = event.currentTarget.dataset.clientName

    // Set the values
    this.inputTarget.value = clientName
    this.hiddenFieldTarget.value = clientId

    // Hide results
    this.hideResults()

    // Remove focus from input to prevent reopening results
    this.inputTarget.blur()
  }

  showResults() {
    if (this.hasResultsTarget) {
      this.resultsTarget.classList.remove("hidden")
      document.addEventListener("click", this.boundHandleDocumentClick)
    }
  }

  hideResults() {
    if (this.hasResultsTarget && !this.isMouseOverResults) {
      this.resultsTarget.classList.add("hidden")
      document.removeEventListener("click", this.boundHandleDocumentClick)
    }
  }

  handleMouseEnter() {
    this.isMouseOverResults = true
  }

  handleMouseLeave() {
    this.isMouseOverResults = false
  }

  handleDocumentClick(event) {
    if (!this.element.contains(event.target)) {
      this.hideResults()
    }
  }

  toggleField(event) {
    const roleSelect = event.target
    const selectedRole = roleSelect.value
    
    if (selectedRole === "client") {
      this.containerTarget.classList.remove("hidden")
    } else {
      this.containerTarget.classList.add("hidden")
      this.clearValues()
    }
  }

  clearValues() {
    if (this.hasInputTarget) this.inputTarget.value = ""
    if (this.hasHiddenFieldTarget) this.hiddenFieldTarget.value = ""
    this.hideResults()
  }

  clearDebounceTimer() {
    if (this.debounceTimer) {
      clearTimeout(this.debounceTimer)
      this.debounceTimer = null
    }
  }

  escapeHtml(text) {
    const div = document.createElement('div')
    div.textContent = text
    return div.innerHTML
  }
}