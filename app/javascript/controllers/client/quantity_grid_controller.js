import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "quantityInput",
    "rowTotal",
    "colTotal",
    "grandTotal",
    "totalQuantity",
    "pricePerUnit",
    "estimatedTotal",
    "feedbackMessage"
  ]

  connect() {
    // Store product pricing data from data attributes
    this.basePrice = parseFloat(this.element.dataset.basePrice || 0)
    this.minimumOrder = parseInt(this.element.dataset.minimumOrder || 0)

    // Parse bulk pricing from data attribute and sort descending
    try {
      this.bulkPrices = JSON.parse(this.element.dataset.bulkPrices || '[]')
                            .sort((a, b) => parseInt(b.qty) - parseInt(a.qty))
    } catch (e) {
      console.error("Failed to parse bulk prices:", e)
      this.bulkPrices = []
    }

    console.log("Quantity Grid Controller connected", {
      basePrice: this.basePrice,
      minimumOrder: this.minimumOrder,
      bulkPrices: this.bulkPrices
    })
  }

  updateTotals() {
    // Initialize totals objects
    const rowTotals = {}
    const colTotals = {}

    // Pre-initialize row totals
    this.rowTotalTargets.forEach(target => {
      const row = target.dataset.row
      rowTotals[row] = 0
    })

    // Pre-initialize column totals
    this.colTotalTargets.forEach(target => {
      const col = target.dataset.col
      colTotals[col] = 0
    })

    // Calculate all totals by iterating through inputs
    let grandTotal = 0
    this.quantityInputTargets.forEach(input => {
      const qty = parseInt(input.value || 0)
      const row = input.dataset.row
      const col = input.dataset.col

      rowTotals[row] = (rowTotals[row] || 0) + qty
      colTotals[col] = (colTotals[col] || 0) + qty
      grandTotal += qty
    })

    // Update row total displays
    this.rowTotalTargets.forEach(target => {
      const row = target.dataset.row
      target.textContent = rowTotals[row] || 0
    })

    // Update column total displays
    this.colTotalTargets.forEach(target => {
      const col = target.dataset.col
      target.textContent = colTotals[col] || 0
    })

    // Update grand total displays
    if (this.hasGrandTotalTarget) {
      this.grandTotalTarget.textContent = grandTotal
    }
    if (this.hasTotalQuantityTarget) {
      this.totalQuantityTarget.textContent = grandTotal
    }

    // Update pricing based on quantity
    this.updatePricing(grandTotal)

    // Update feedback messages
    this.updateFeedback(grandTotal)
  }

  updatePricing(totalQuantity) {
    // Determine applicable price based on bulk pricing tiers
    let applicablePrice = this.basePrice
    let appliedTier = null

    // Bulk prices are sorted descending, so find first match
    for (const bulk of this.bulkPrices) {
      const tierQty = parseInt(bulk.qty)
      if (totalQuantity >= tierQty) {
        applicablePrice = parseFloat(bulk.price)
        appliedTier = bulk
        break
      }
    }

    // Update price per unit display
    if (this.hasPricePerUnitTarget) {
      this.pricePerUnitTarget.textContent = `$${applicablePrice.toFixed(2)}`
    }

    // Calculate and update estimated total
    const estimatedTotal = applicablePrice * totalQuantity
    if (this.hasEstimatedTotalTarget) {
      this.estimatedTotalTarget.textContent = `$${estimatedTotal.toFixed(2)}`
    }

    return { applicablePrice, appliedTier }
  }

  updateFeedback(totalQuantity) {
    if (!this.hasFeedbackMessageTarget) return

    let message = ""
    let messageClass = ""

    // Priority 1: Check minimum order requirement
    if (this.minimumOrder > 0 && totalQuantity > 0 && totalQuantity < this.minimumOrder) {
      const remaining = this.minimumOrder - totalQuantity
      message = `⚠️ Add ${remaining} more unit${remaining === 1 ? '' : 's'} to meet minimum order requirement (${this.minimumOrder} units total)`
      messageClass = "text-amber-600 font-semibold bg-amber-50 border border-amber-200 rounded-lg px-4 py-3"
    }
    // Priority 2: Check if close to next bulk pricing tier
    else if (totalQuantity > 0 && this.bulkPrices.length > 0) {
      // Get tiers in ascending order for this check
      const ascendingTiers = [...this.bulkPrices].reverse()

      let showedNudge = false
      for (const bulk of ascendingTiers) {
        const tierQty = parseInt(bulk.qty)
        if (totalQuantity < tierQty) {
          const remaining = tierQty - totalQuantity
          const tierPrice = parseFloat(bulk.price)

          // Show nudge if within 15 units of next tier
          if (remaining <= 15) {
            const savings = (this.basePrice - tierPrice).toFixed(2)
            message = `💡 Add just ${remaining} more unit${remaining === 1 ? '' : 's'} to unlock bulk pricing at $${tierPrice.toFixed(2)}/unit (save $${savings} per unit)!`
            messageClass = "text-green-700 font-semibold bg-green-50 border border-green-200 rounded-lg px-4 py-3"
            showedNudge = true
            break
          }
        }
      }

      // Priority 3: If already at bulk pricing tier, show confirmation
      if (!showedNudge && totalQuantity >= parseInt(this.bulkPrices[0]?.qty || Infinity)) {
        const currentTier = this.bulkPrices[0]
        const savings = (this.basePrice - parseFloat(currentTier.price)).toFixed(2)
        message = `✅ Bulk pricing applied! You're saving $${savings} per unit with ${totalQuantity} units`
        messageClass = "text-green-700 font-semibold bg-green-50 border border-green-200 rounded-lg px-4 py-3"
      }
    }

    this.feedbackMessageTarget.innerHTML = message
    this.feedbackMessageTarget.className = `mt-2 text-sm ${messageClass}`
  }

  increment(event) {
    event.preventDefault()
    const input = event.currentTarget.closest('[data-size-cell]')
      ?.querySelector('[data-quantity-grid-target="quantityInput"]')

    if (input) {
      input.value = parseInt(input.value || 0) + 1
      this.updateTotals()
    }
  }

  decrement(event) {
    event.preventDefault()
    const input = event.currentTarget.closest('[data-size-cell]')
      ?.querySelector('[data-quantity-grid-target="quantityInput"]')

    if (input) {
      const current = parseInt(input.value || 0)
      if (current > 0) {
        input.value = current - 1
        this.updateTotals()
      }
    }
  }

  validateBeforeSubmit(event) {
    const total = parseInt(this.grandTotalTarget?.textContent || 0)

    // Check if any items selected
    if (total === 0) {
      event.preventDefault()
      alert("Please select at least one item to add to cart.")
      return false
    }

    // Check minimum order requirement
    if (this.minimumOrder > 0 && total < this.minimumOrder) {
      event.preventDefault()
      alert(`⚠️ Minimum order quantity is ${this.minimumOrder} units.\n\nYou have selected ${total} units.\n\nPlease add ${this.minimumOrder - total} more units to proceed.`)
      return false
    }

    // If validation passes, allow form submission (Turbo will handle it)
    return true
  }
}
