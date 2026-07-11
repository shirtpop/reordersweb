import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    window.dispatchEvent(new CustomEvent("cart-drawer:open"))
    this.element.remove()
  }
}
