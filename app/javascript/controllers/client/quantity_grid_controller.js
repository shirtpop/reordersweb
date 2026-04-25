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
    "feedbackMessage",
    "colorMinimum"
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

    // Build per-color minimum order map
    this.colorMinimums = {}
    this.colorMinimumTargets.forEach(input => {
      const color = input.dataset.color
      const min = parseInt(input.value || 0)
      if (min > 0) this.colorMinimums[color] = min
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

    // Priority 1: Per-color and total minimum checks
    const violations = []

    this.colTotalTargets.forEach(target => {
      const color = target.dataset.col
      const colorTotal = parseInt(target.textContent || 0)
      const colorMin = this.colorMinimums[color] || 0

      if (colorMin > 0) {
        // Required color — must be ordered and meet its own minimum
        if (colorTotal < colorMin) {
          violations.push(`${color}: add ${colorMin - colorTotal} more (required min ${colorMin})`)
        }
      } else if (this.minimumOrder > 0 && colorTotal > 0 && colorTotal < this.minimumOrder) {
        // Optional color ordered below the product minimum run size
        violations.push(`${color}: add ${this.minimumOrder - colorTotal} more (min ${this.minimumOrder} per color)`)
      }
    })

    // Total must meet the product minimum
    if (this.minimumOrder > 0 && totalQuantity < this.minimumOrder) {
      violations.push(`total: add ${this.minimumOrder - totalQuantity} more (min ${this.minimumOrder} overall)`)
    }

    if (violations.length > 0) {
      message = `⚠️ Minimum not met: ${violations.join(" · ")}`
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

    // Check per-color and total minimum requirements
    const violations = []

    this.colTotalTargets.forEach(target => {
      const color = target.dataset.col
      const colorTotal = parseInt(target.textContent || 0)
      const colorMin = this.colorMinimums[color] || 0

      if (colorMin > 0) {
        if (colorTotal < colorMin) {
          violations.push(`• ${color}: ${colorTotal} selected, required minimum is ${colorMin}`)
        }
      } else if (this.minimumOrder > 0 && colorTotal > 0 && colorTotal < this.minimumOrder) {
        violations.push(`• ${color}: ${colorTotal} selected, minimum per color is ${this.minimumOrder}`)
      }
    })

    if (this.minimumOrder > 0 && total < this.minimumOrder) {
      violations.push(`• Total: ${total} selected, overall minimum is ${this.minimumOrder}`)
    }

    if (violations.length > 0) {
      event.preventDefault()
      alert(`⚠️ Minimum order requirements not met:\n\n${violations.join("\n")}`)
      return false
    }

    // Nothing selected and no minimum violations (product has no required colors or minimums)
    if (total === 0) {
      event.preventDefault()
      const hasRequiredColors = Object.keys(this.colorMinimums).length > 0
      if (hasRequiredColors) {
        alert(`⚠️ Please enter quantities for all required colors to meet their minimum orders.`)
      } else if (this.minimumOrder > 0) {
        alert(`⚠️ Please enter at least ${this.minimumOrder} units to add to cart.`)
      } else {
        alert("Please select at least one item to add to cart.")
      }
      return false
    }

    // If validation passes, allow form submission (Turbo will handle it)
    return true
  }
}
