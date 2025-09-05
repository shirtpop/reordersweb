import { application } from "controllers/application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"

import "@hotwired/turbo-rails"
import { initFlowbite } from "flowbite"

eagerLoadControllersFrom("controllers/client", application)
eagerLoadControllersFrom("controllers/shared", application)

document.addEventListener("turbo:load", () => {
  initFlowbite()
})