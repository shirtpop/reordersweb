# Detects an in-progress devise_masquerade session straight from the raw
# Rack session, before Devise/Warden ever calls current_user. Controller
# before_actions run too late for this: Devise::MasqueradesController's own
# prepend_before_action triggers Warden authentication (and its Activatable
# hook) before our ApplicationController callbacks get a chance to run.
class MasqueradeContext
  SESSION_KEY = "devise_masquerade_masquerading_resource_guid"

  def initialize(app)
    @app = app
  end

  def call(env)
    Current.masquerading = env["rack.session"]&.[](SESSION_KEY).present?
    @app.call(env)
  end
end
