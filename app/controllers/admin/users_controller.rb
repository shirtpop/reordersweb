module Admin
  class UsersController < BaseController
    before_action :set_user, only: [:update, :destroy]

    def index
      scope = params[:q].present? ? User.where("email ILIKE ?", "%#{params[:q]}%") : User.order(created_at: :desc)
      @pagy, @users = pagy(scope)
    end

    def create
      @user = User.new(user_params)
      
      respond_to do |format|
        if @user.save
          UserMailer.with(user: @user, password: user_params[:password]).welcome_client.deliver_later
          format.html { 
            redirect_to admin_users_path, 
            notice: 'User was successfully created.' 
          }
          format.json { 
            render json: { 
              status: 'success', 
              message: 'User created successfully',
              user: {
                id: @user.id,
                email: @user.email,
                role: @user.role
              }
            }, status: :created
          }
        else
          format.html { 
            # Re-render the index page with modal open and errors
            @users = User.includes(:client).order(:email).page(params[:page])
            render :index, status: :unprocessable_entity
          }
          format.json { 
            render json: { 
              status: 'error', 
              errors: @user.errors.full_messages 
            }, status: :unprocessable_entity 
          }
        end
      end
    end

    def update
      respond_to do |format|
        if @user.update(user_update_params)
          format.html { 
            redirect_to admin_users_path, 
            notice: 'User was successfully updated.' 
          }
          format.json { 
            render json: { 
              status: 'success', 
              message: 'User updated successfully',
              user: {
                id: @user.id,
                email: @user.email,
                role: @user.role
              }
            }
          }
        else
          format.html { 
            # Re-render with errors
            render :edit, status: :unprocessable_entity 
          }
          format.json { 
            render json: { 
              status: 'error', 
              errors: @user.errors.full_messages 
            }, status: :unprocessable_entity 
          }
        end
      end
    end

    def destroy
      @user.destroy
      respond_to do |format|
        format.html { 
          redirect_to admin_users_path, 
          notice: 'User was successfully deleted.' 
        }
        format.json { 
          render json: { 
            status: 'success', 
            message: 'User deleted successfully' 
          }
        }
      end
    end

    private

    def user_params
      permitted_params = [:email, :password, :password_confirmation, :role]
      
      # Only allow client_id if role is 'client'
      if params[:user][:role] == 'client'
        permitted_params << :client_id
      end
      
      params.require(:user).permit(permitted_params)
    end

    def user_update_params
      permitted_params = [:email, :role]
      
      # Include password fields only if they are provided
      if params[:user][:password].present?
        permitted_params += [:password, :password_confirmation]
      end
      
      # Only allow client_id if role is 'client'
      if params[:user][:role] == 'client'
        permitted_params << :client_id
      end
      
      params.require(:user).permit(permitted_params)
    end

    def set_user
      @user = User.find(params[:id])
    end
  end
end