import { application } from "controllers/application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"

import "@hotwired/turbo-rails"
import { initFlowbite } from "flowbite"

eagerLoadControllersFrom("controllers/client", application)
eagerLoadControllersFrom("controllers/shared", application)

// Initialize Flowbite on page load and after Turbo navigation
document.addEventListener("turbo:load", () => {
  initFlowbite()
})

// Re-initialize Flowbite after Turbo frame renders (for dynamic content)
document.addEventListener("turbo:frame-render", () => {
  initFlowbite()
})