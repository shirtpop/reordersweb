import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel", "backdrop"]

  connect() {
    this.boundOpen = () => this.open()
    this.boundKeydown = (event) => {
      if (event.key === "Escape" && this.isOpen) this.close()
    }
    window.addEventListener("cart-drawer:open", this.boundOpen)
    document.addEventListener("keydown", this.boundKeydown)
  }

  disconnect() {
    window.removeEventListener("cart-drawer:open", this.boundOpen)
    document.removeEventListener("keydown", this.boundKeydown)
    document.body.style.overflow = ""
  }

  open() {
    this.panelTarget.classList.remove("translate-x-full")
    this.backdropTarget.classList.remove("hidden", "opacity-0")
    document.body.style.overflow = "hidden"
    this.isOpen = true
  }

  close() {
    this.panelTarget.classList.add("translate-x-full")
    this.backdropTarget.classList.add("opacity-0")
    setTimeout(() => this.backdropTarget.classList.add("hidden"), 300)
    document.body.style.overflow = ""
    this.isOpen = false
  }

  closeOnBackdrop(event) {
    if (event.target === this.backdropTarget) this.close()
  }
}
