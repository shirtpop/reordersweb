class ProductsController < BaseController
  before_action :set_product, only: [ :show, :edit, :update ]

  def index
    scope = params[:q].present? ? current_client.client_products.search_by_name(params[:q]) : current_client.client_products
    @pagy, @products = pagy(scope.includes(:drive_files, :admin_product, product_variants: :inventory))
  end

  def show; end

  def new
    @product = current_client.client_products.new
    @product.product_variants.build
  end

  def create
    @product = current_client.client_products.new(product_params)

    if @product.save
      redirect_to products_path, notice: "Product was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    @product = current_client.client_products.find(params[:id])

    if @product.update(product_params)
      redirect_to products_path, notice: "Product was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def admin_products
    @products = Product.joins(products_projects: :project)
                       .merge(Project.where(client: current_client))
                       .merge(Product.search_by_name(params[:q]))
                       .includes(:rich_text_description)
  end

  def upload_images
    GoogleDrive::Uploader.new(file: drive_file_params[:file], attachable: @product).call!

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "images_container_client_product",
          partial: "products/images_section",
          locals: { product: @product }
        )
      end
    end
  rescue GoogleDrive::Uploader::UploadError => e
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "images_container_client_product",
          partial: "shared/error_message",
          locals: { message: "Failed to upload file: #{e.message}" }
        )
      end
    end
  end

  def delete_image
    @drive_file = @product.drive_files.find(params[:drive_file_id])
    @drive_file.destroy!

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "images_container_client_product",
          partial: "products/images_section",
          locals: { product: @product }
        )
      end
    end
  rescue ActiveRecord::RecordNotFound, GoogleDrive::Errors::DeleteError => e
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "images_container_client_product",
          partial: "shared/error_message",
          locals: { message: e.message }
        )
      end
    end
  end

  def barcodes
    @products = current_client.client_products.includes(:product_variants)
  end

  private

  def set_product
    @product = current_client.client_products.find(params[:id])
  end

  def product_params
    params.require(:client_product).permit(:name, :description, :product_id,
      product_variants_attributes: [ :id, :color, :size, :sku, :_destroy ])
  end

  def drive_file_params
    params.permit(:file)
  end
end
