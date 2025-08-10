import { Application } from "@hotwired/stimulus"

import "trix"
import "@rails/actiontext"

const application = Application.start()

// Configure Stimulus development experience
application.debug = true
window.Stimulus   = application

export { application }
