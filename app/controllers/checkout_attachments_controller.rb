class CheckoutAttachmentsController < BaseController
  before_action :set_cart

  def create
    file = params[:file]
    error = validate(file)
    raise GoogleDrive::Uploader::UploadError, error if error

    GoogleDrive::Uploader.new(file: file, attachable: @cart).call!
    render_attachments
  rescue GoogleDrive::Uploader::UploadError => e
    render_attachments(error: e.message)
  end

  def destroy
    @cart.drive_files.find(params[:id]).destroy!
    render_attachments
  rescue ActiveRecord::RecordNotFound
    render_attachments(error: "File not found.")
  end

  private

  def set_cart
    @cart = current_user.in_cart_order
    head :not_found unless @cart
  end

  def validate(file)
    return "No file selected." unless file.respond_to?(:original_filename)
    return "You can attach up to #{Order.max_drive_files} files." if @cart.drive_files.count >= Order.max_drive_files

    extension = File.extname(file.original_filename).downcase
    unless Order::ATTACHMENT_EXTENSIONS.include?(extension) && Order::ATTACHMENT_CONTENT_TYPES.include?(file.content_type)
      return "#{file.original_filename} is not allowed. Only images and PDF files can be uploaded."
    end

    "#{file.original_filename} is larger than #{Order::MAX_ATTACHMENT_SIZE / 1.megabyte} MB." if file.size > Order::MAX_ATTACHMENT_SIZE
  end

  def render_attachments(error: nil)
    render turbo_stream: turbo_stream.replace(
      "checkout_attachments",
      partial: "order_checkouts/attachments",
      locals: { order: @cart.reload, error: error }
    )
  end
end
