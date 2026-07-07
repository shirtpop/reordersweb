module Admin
  class MasqueradesController < Devise::MasqueradesController
    protected

    def masquerade_authorize!
      head(403) unless user_masquerade? || current_user&.role_admin?
    end

    def after_masquerade_path_for(resource)
      root_path
    end

    def after_back_masquerade_path_for(resource)
      admin_users_path
    end
  end
end
