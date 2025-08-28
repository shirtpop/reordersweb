# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  skip_before_action :force_password_change

  protected

  def update_resource(resource, params)
    if resource.role_client? && resource.first_time_login?
      resource.update(params.merge(first_time_login: false))
    else
      super
    end
  end
end
