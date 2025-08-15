import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sameAsMain", "shippingFields", "mainField", "shippingField"]

  connect() {
    this.toggleShippingFields()
  }

  toggle() {
    this.toggleShippingFields()
    if (this.sameAsMainTarget.checked) {
      this.copyMainToShipping()
      // Clear shipping fields since they won't be used
      this.clearShippingFields()
    }
  }

  updateShipping() {
    if (this.sameAsMainTarget.checked) {
      this.copyMainToShipping()
    }
  }

  toggleShippingFields() {
    if (this.sameAsMainTarget.checked) {
      this.shippingFieldsTarget.style.display = 'none'
    } else {
      this.shippingFieldsTarget.style.display = 'block'
      this.shippingFieldTargets.forEach(field => {
        field.setAttribute('required', 'true')
      })
    }
  }

  copyMainToShipping() {
    this.mainFieldTargets.forEach((mainField, index) => {
      const shippingField = this.shippingFieldTargets[index]
      if (shippingField && mainField.name && shippingField.name) {
        // Match fields by their field type (street, city, state, zip_code)
        const mainFieldType = this.extractFieldType(mainField.name)
        const shippingFieldType = this.extractFieldType(shippingField.name)
        
        if (mainFieldType === shippingFieldType) {
          shippingField.value = mainField.value
        }
      }
    })
  }

  clearShippingFields() {
    // Clear shipping fields when same_as_main is checked
    // This prevents validation errors on hidden fields
    if (this.sameAsMainTarget.checked) {
      this.shippingFieldTargets.forEach(field => {
        field.value = ''
        field.removeAttribute('required')
      })
    }
  }

  extractFieldType(fieldName) {
    // Extract field type from names like "client[address_attributes][street]" or "client[shipping_address_attributes][city]"
    const match = fieldName.match(/\[([^\]]+)\]$/)
    return match ? match[1] : null
  }
}