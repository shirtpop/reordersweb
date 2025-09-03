module Admin
  class ProjectsController < BaseController
    before_action :set_project, only: [ :edit, :show, :update, :destroy ]

    def index
      scope = params[:q].present? ? Project.search_by_keyword(params[:q]) : Project.includes(:client).order(created_at: :desc)
      @pagy, @projects = pagy(scope)
    end

    def show; end

    def new
      @project = Project.new
    end

    def create
      @project = Project.new(project_params)

      if @project.save
        redirect_to admin_projects_path, notice: "Project was successfully created."
      else
        render :new
      end
    end

    def edit; end

    def update
      if @project.update(project_params)
        update_project_products
        redirect_to admin_projects_path, notice: "Project was successfully updated."
      else
        render :edit
      end
    end

    def destroy
      @project.destroy!
      redirect_to admin_projects_path, notice: "Project was successfully deleted."
    end

    private

    def set_project
      @project = Project.find(params[:id])
    end

    def project_params
      params.require(:project).permit(:name, :status, :client_id, :description, product_ids: [])
    end

    def update_project_products
      return unless params[:project][:product_ids]

      # Get the selected product IDs, filtering out empty values
      selected_product_ids = params[:project][:product_ids].reject(&:blank?).map(&:to_i)

      # Get current product IDs
      current_product_ids = @project.product_ids

      # Remove products that are no longer selected
      products_to_remove = current_product_ids - selected_product_ids
      if products_to_remove.any?
        @project.product_projects.where(product_id: products_to_remove).destroy_all
      end

      # Add new products
      products_to_add = selected_product_ids - current_product_ids
      products_to_add.each do |product_id|
        @project.product_projects.create!(product_id: product_id)
      end
    end
  end
end
