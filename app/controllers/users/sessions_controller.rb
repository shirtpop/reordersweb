# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  layout 'auth'

  private
  
  def after_sign_in_path_for(resource)
    if resource.role_admin?
      admin_root_path
    else
      root_path
    end
  end

  def after_sign_out_path_for(resource_or_scope)
    if resource_or_scope == :user || resource_or_scope == User
      new_user_session_path
    else
      super
    end
  end
end