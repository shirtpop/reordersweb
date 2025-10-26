// app/javascript/controllers/client/client_product_form_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["variantsContainer", "variantTemplate", "variantRow"]

  connect() {
    this.variantIndex = this.getNextVariantIndex()
  }

  addVariant() {
    const template = this.variantTemplateTarget
    
    if (!template) {
      console.error('Template not found')
      return
    }
    
    // Clone the template content
    const templateContent = template.content.cloneNode(true)
    
    // Get the first element from the template
    const templateElement = templateContent.firstElementChild
    
    if (!templateElement) {
      console.error('Template has no content')
      return
    }
    
    // Replace INDEX placeholder with actual index in all input names
    const inputs = templateElement.querySelectorAll('input[name*="INDEX"]')
    inputs.forEach(input => {
      input.name = input.name.replace(/INDEX/g, this.variantIndex)
    })
    
    // Append the new variant row
    this.variantsContainerTarget.appendChild(templateElement)
    
    this.variantIndex++
  }

  removeVariant(event) {
    const variantRow = event.target.closest('[data-client-product-form-target="variantRow"]')
    if (variantRow) {
      const destroyField = variantRow.querySelector('input[name*="[_destroy]"]')
      if (destroyField) {
        destroyField.value = 'true'
      }
      variantRow.style.display = 'none'
    }
  }

  getNextVariantIndex() {
    // Count existing variant rows to determine next index
    const existingRows = this.variantsContainerTarget.querySelectorAll('[data-client-product-form-target="variantRow"]')
    return existingRows.length
  }
}