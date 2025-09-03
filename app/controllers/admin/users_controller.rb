module Admin
  class UsersController < BaseController
    before_action :set_user, only: [ :show, :edit, :update, :destroy ]

    def index
      scope = params[:q].present? ? User.where("email ILIKE ?", "%#{params[:q]}%") : User.includes(:client).order(created_at: :desc)
      @pagy, @users = pagy(scope)
    end

    def new
      @user = User.new
    end

    def create
      @user = User.new(user_params)

      if @user.save
        pagy, users = pagy(User.order(created_at: :desc))
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: [
              turbo_stream.update("user_modal", ""),
              turbo_stream.replace("users_list", partial: "table", locals: {
                users: users,
                pagy: pagy
              }),
              turbo_stream.prepend("flash", partial: "admin/flash", locals: {
                type: "success",
                message: "User was successfully created."
              })
            ]
          end
          format.html { redirect_to admin_users_path, notice: "User was successfully created." }
        end
      else
        render :new, status: :unprocessable_entity
      end
    end

    def update
      if @user.update(user_params)
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: [
              turbo_stream.update("user_modal", ""),
              turbo_stream.prepend("flash", partial: "admin/flash", locals: {
                type: "success",
                message: "User was successfully updated."
              })
            ]
          end
          format.html { redirect_to admin_users_path, notice: "User was successfully updated." }
        end
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @user.destroy
      pagy, users = pagy(User.order(created_at: :desc))

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("users_list", partial: "table", locals: {
              users: users,
              pagy: pagy
            }),
            turbo_stream.prepend("flash", partial: "admin/flash", locals: {
              type: "success",
              message: "User was successfully deleted."
            })
          ]
        end
        format.html { redirect_to admin_users_path, notice: "User was successfully deleted." }
      end
    end

    private

    def user_params
      permitted_params = [ :email, :password, :password_confirmation, :role ]

      # Only allow client_id if role is 'client'
      if params[:user][:role] == "client"
        permitted_params << :client_id
      end

      params.require(:user).permit(permitted_params)
    end

    def user_update_params
      permitted_params = [ :email, :role ]

      # Include password fields only if they are provided
      if params[:user][:password].present?
        permitted_params += [ :password, :password_confirmation ]
      end

      # Only allow client_id if role is 'client'
      if params[:user][:role] == "client"
        permitted_params << :client_id
      end

      params.require(:user).permit(permitted_params)
    end

    def set_user
      @user = User.find(params[:id])
    end
  end
end
