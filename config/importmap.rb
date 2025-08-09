# Pin npm packages by running ./bin/importmap

# Core Stimulus + Turbo
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"

# Our Stimulus application instance
pin "controllers/application", to: "controllers/application.js"

# Entry points for layouts
pin "admin_application", to: "admin_application.js"
pin "client_application", to: "client_application.js"

# Auto-load controllers by namespace
pin_all_from "app/javascript/controllers/admin", under: "controllers/admin"
pin_all_from "app/javascript/controllers/client", under: "controllers/client"
pin_all_from "app/javascript/controllers/shared", under: "controllers/shared"

# External JS
pin "flowbite", to: "https://cdn.jsdelivr.net/npm/flowbite@3.1.2/dist/flowbite.turbo.min.js"
