# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  skip_before_action :force_password_change

  def update_profile
    if current_user.update(profile_params)
      redirect_to edit_user_registration_path, notice: "Profile updated successfully."
    else
      self.resource = current_user
      render :edit, status: :unprocessable_entity
    end
  end

  protected

  def update_resource(resource, params)
    if resource.role_client? && resource.first_time_login?
      resource.update(params.merge(first_time_login: false))
    else
      super
    end
  end

  private

  def profile_params
    params.require(:user).permit(:first_name, :last_name)
  end
end
