import { Controller } from "@hotwired/stimulus"
import JsBarcode from "jsbarcode"

export default class extends Controller {
  static targets = ["barcode"]

  connect() {
    console.log('Barcode controller connected')
    this.generateBarcodes()
    this.setupPrintListener()
  }

  disconnect() {
    // Clean up print listener
    if (this.boundPrintHandler) {
      window.removeEventListener('beforeprint', this.boundPrintHandler)
    }
  }

  setupPrintListener() {
    this.boundPrintHandler = this.handleBeforePrint.bind(this)
    window.addEventListener('beforeprint', this.boundPrintHandler)
  }

  handleBeforePrint() {
    this.generateBarcodes()
  }

  generateBarcodes() {
    this.barcodeTargets.forEach((barcodeElement) => {
      this.generateBarcode(barcodeElement)
    })
  }

  generateBarcode(barcodeElement) {
    const sku = barcodeElement.dataset.sku
    
    if (!sku || sku.trim() === '') {
      this.showError(barcodeElement, 'No SKU')
      return
    }

    try {
      const options = {
        format: barcodeElement.dataset.format || 'CODE128',
        height: parseInt(barcodeElement.dataset.height) || 60,
        width: parseInt(barcodeElement.dataset.width) || 2,
        displayValue: barcodeElement.dataset.displayValue === 'true',
        fontSize: parseInt(barcodeElement.dataset.fontSize) || 14,
        margin: 10,
        background: '#ffffff',
        lineColor: '#000000'
      }
      
      JsBarcode(barcodeElement, sku, options)
    } catch (error) {
      console.error('Error generating barcode for SKU:', sku, error)
      this.showError(barcodeElement, 'Invalid SKU format')
    }
  }

  showError(barcodeElement, message) {
    const container = barcodeElement.parentElement
    if (container) {
      container.innerHTML = `<p class="text-xs ${message === 'No SKU' ? 'text-gray-500 italic' : 'text-red-500'}">${message}</p>`
    }
  }
}

