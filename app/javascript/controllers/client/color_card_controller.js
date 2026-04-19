import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["heroImage", "angleThumbnail", "heroPlaceholder"]

  switchAngle(event) {
    const button = event.currentTarget
    const url = button.dataset.url

    if (this.hasHeroImageTarget && url) {
      this.heroImageTarget.src = url
    }

    this.angleThumbnailTargets.forEach(thumb => {
      thumb.classList.toggle("ring-2", thumb === button)
      thumb.classList.toggle("ring-pink-500", thumb === button)
      thumb.classList.toggle("border-pink-500", thumb === button)
      thumb.classList.toggle("border-transparent", thumb !== button)
    })
  }
}
