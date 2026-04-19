// app/javascript/controllers/product_form_controller.js
import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="product-form"
export default class extends Controller {
  static targets = [
    "bulkPricesContainer", 
    "bulkPriceTemplate", 
    "bulkPriceRow", 
    "colorsContainer", 
    "colorTemplate", 
    "colorRow"
  ]

  connect() {
    // Sync existing color pickers with text inputs
    this.syncExistingColorInputs()
  }

  addBulkPrice() {
    const template = this.bulkPriceTemplateTarget.content.cloneNode(true)
    this.bulkPricesContainerTarget.appendChild(template)
  }

  removeBulkPrice(event) {
    event.target.closest('.bulk-price-row').remove()
  }

  addColor() {
    const timestamp = Date.now()
    const templateHTML = this.colorTemplateTarget.innerHTML.replace(/NEW_RECORD/g, timestamp)

    this.colorsContainerTarget.insertAdjacentHTML("beforeend", templateHTML)

    const newRow = this.colorsContainerTarget.lastElementChild

    this.syncColorInputs(newRow)
  }

  removeColor(event) {
    const row = event.target.closest(".color-row")
    const destroyField = row.querySelector("[data-product-form-target~='colorDestroyField']")
    const idField = row.querySelector("input[name*='[id]']")

    if (idField && idField.value) {
      // Persisted record: mark for destruction and hide
      if (destroyField) destroyField.value = "1"
      row.style.display = "none"
    } else {
      row.remove()
    }
  }

  // Private methods
  syncExistingColorInputs() {
    this.colorRowTargets.forEach(row => this.syncColorInputs(row))
  }

  syncColorInputs(colorRow) {
    const colorPicker = colorRow.querySelector("[data-product-form-target~='colorPicker']")
    const hexInput = colorRow.querySelector("[data-product-form-target~='colorHexInput']")

    if (colorPicker && hexInput) {
      colorPicker.addEventListener("input", (e) => {
        hexInput.value = e.target.value.toUpperCase()
      })

      hexInput.addEventListener("input", (e) => {
        const hexValue = e.target.value.trim()
        if (this.isValidHexColor(hexValue)) {
          colorPicker.value = hexValue
        }
      })
    }
  }

  isValidHexColor(hex) {
    return /^#[0-9A-F]{6}$/i.test(hex)
  }

  setupToolbarButtons() {
    const buttons = [
      { id: 'toggleBoldButton', action: () => this.editor.chain().focus().toggleBold().run() },
      { id: 'toggleItalicButton', action: () => this.editor.chain().focus().toggleItalic().run() },
      { id: 'toggleUnderlineButton', action: () => this.editor.chain().focus().toggleUnderline().run() },
      { id: 'toggleListButton', action: () => this.editor.chain().focus().toggleBulletList().run() },
      { id: 'toggleOrderedListButton', action: () => this.editor.chain().focus().toggleOrderedList().run() }
    ]

    buttons.forEach(({ id, action }) => {
      const button = document.getElementById(id)
      if (button) {
        button.addEventListener('click', (e) => {
          e.preventDefault()
          action()
        })
      }
    })
  }

  disconnect() {
    // Clean up the editor when controller is disconnected
    if (this.editor) {
      this.editor.destroy()
    }
  }
}