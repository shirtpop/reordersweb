import { application } from "controllers/application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"

import "@hotwired/turbo-rails"
import "flowbite"

eagerLoadControllersFrom("controllers/admin", application)
eagerLoadControllersFrom("controllers/shared", application)

// Initialize Flowbite after Turbo navigations
document.addEventListener('turbo:load', () => {
  if (typeof window.initFlowbite === 'function') {
    window.initFlowbite()
  }
})