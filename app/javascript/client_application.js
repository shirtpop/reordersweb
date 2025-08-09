import { application } from "controllers/application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"

import "@hotwired/turbo-rails"
import "flowbite"

eagerLoadControllersFrom("controllers/client", application)
eagerLoadControllersFrom("controllers/shared", application)
