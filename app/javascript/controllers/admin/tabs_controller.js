import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel"]
  static values = { active: { type: Number, default: 0 } }

  connect() {
    this.showTab(this.activeValue)
  }

  switch(event) {
    const index = this.tabTargets.indexOf(event.currentTarget)
    this.activeValue = index
    this.showTab(index)
  }

  showTab(index) {
    this.tabTargets.forEach((tab, i) => {
      const isActive = i === index
      tab.classList.toggle("border-blue-600", isActive)
      tab.classList.toggle("text-blue-600", isActive)
      tab.classList.toggle("dark:border-blue-400", isActive)
      tab.classList.toggle("dark:text-blue-400", isActive)
      tab.classList.toggle("font-medium", isActive)
      tab.classList.toggle("border-transparent", !isActive)
      tab.classList.toggle("text-gray-500", !isActive)
      tab.classList.toggle("dark:text-gray-400", !isActive)
    })

    this.panelTargets.forEach((panel, i) => {
      panel.classList.toggle("hidden", i !== index)
    })
  }
}
