# Must run before Warden::Manager so Current.masquerading is set before
# Devise/Warden authenticates the request (see app/middleware/masquerade_context.rb).
require Rails.root.join("app/middleware/masquerade_context")

Rails.application.config.middleware.insert_before Warden::Manager, MasqueradeContext
