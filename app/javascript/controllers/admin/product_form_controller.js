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
    const template = this.colorTemplateTarget.content.cloneNode(true)
    this.colorsContainerTarget.appendChild(template)
    
    // Sync color picker with text input for the newly added row
    const colorRow = this.colorsContainerTarget.lastElementChild
    this.syncColorInputs(colorRow)
  }

  removeColor(event) {
    event.target.closest('.color-row').remove()
  }

  // Private methods
  syncExistingColorInputs() {
    this.colorRowTargets.forEach(row => {
      this.syncColorInputs(row)
    })
  }

  syncColorInputs(colorRow) {
    const colorInput = colorRow.querySelector('input[type="color"]')
    const textInput = colorRow.querySelector('input[name="product[colors][][hex_color]"]')

    if (colorInput && textInput) {
      // Update text input when color picker changes
      colorInput.addEventListener('input', (e) => {
        textInput.value = e.target.value.toUpperCase()
      })
      
      // Update color picker when text input changes (if valid hex)
      textInput.addEventListener('input', (e) => {
        const hexValue = e.target.value.trim()
        if (this.isValidHexColor(hexValue)) {
          colorInput.value = hexValue
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