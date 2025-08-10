import { Controller } from "@hotwired/stimulus"

// Usage:
// <form data-controller="shared--search"
//       data-shared--search-target="form"
//       data-shared--search-min-length-value="3"
//       data-shared--search-delay-value="300"
//       data-shared--search-url-value="/admin/users">
//   ...
// </form>
//
// The server must respond with a Turbo Stream replacing the table partial.

export default class extends Controller {
  static targets = ["input", "form"]
  static values = {
    url: String,
    minLength: { type: Number, default: 3 },
    delay: { type: Number, default: 300 }
  }

  connect() {
    this.timeout = null
  }

  search(event) {
    clearTimeout(this.timeout)
    const query = this.inputTarget.value.trim()

    if (query.length < this.minLengthValue && query.length !== 0) {
      return // do nothing if below min length but not empty
    }

    this.timeout = setTimeout(() => {
      if (query === "") {
        this.performSearch("")
      } else {
        this.performSearch(query)
      }
    }, this.delayValue)
  }

  performSearch(query) {
    const url = new URL(this.urlValue || this.formTarget.action, window.location.origin)
    url.searchParams.set("q", query)

    fetch(url, {
      headers: { Accept: "text/vnd.turbo-stream.html" }
    })
    .then(r => r.text())
    .then(html => Turbo.renderStreamMessage(html))
  }
}
