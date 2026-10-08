require 'rails_helper'

RSpec.describe "CheckoutAttachments", type: :request do
  let(:client) { create(:client) }
  let(:catalog) { create(:catalog, client: client) }
  let(:user) { create(:user, client: client, role: :client, active: true, first_time_login: false) }
  let(:product) { create(:product) }

  let!(:cart) do
    order = build(:order, client: client, catalog: catalog, status: :cart, ordered_by: user)
    order.order_items = [ build(:order_item, order: order, product: product, quantity: 10) ]
    order.save!
    order
  end

  let(:headers) { { "Accept" => "text/vnd.turbo-stream.html" } }

  def upload(name, type)
    Rack::Test::UploadedFile.new(StringIO.new("data"), type, original_filename: name)
  end

  before do
    sign_in user
    allow(GoogleDrive::DriveService).to receive(:upload_file).and_return("drive-id")
  end

  describe "POST /checkout/attachments" do
    it "attaches an image or PDF to the cart" do
      expect {
        post checkout_attachments_path, params: { file: upload("po.pdf", "application/pdf") }, headers: headers
      }.to change { cart.drive_files.count }.by(1)

      expect(response).to have_http_status(:ok)
    end

    it "rejects other file types" do
      expect {
        post checkout_attachments_path, params: { file: upload("a.exe", "application/octet-stream") }, headers: headers
      }.not_to change { cart.drive_files.count }

      expect(response.body).to include("not allowed")
    end

    it "rejects a third file" do
      2.times { post checkout_attachments_path, params: { file: upload("a.png", "image/png") }, headers: headers }

      expect {
        post checkout_attachments_path, params: { file: upload("b.png", "image/png") }, headers: headers
      }.not_to change { cart.drive_files.count }
      expect(response.body).to include("up to 2 files")
    end
  end

  describe "DELETE /checkout/attachments/:id" do
    it "removes a file from the cart" do
      file = cart.drive_files.create!(drive_file_id: "x", filename: "a.png", mime_type: "image/png")

      expect {
        delete checkout_attachment_path(file), headers: headers
      }.to change { cart.drive_files.count }.by(-1)
    end

    it "cannot remove another user's file" do
      other_user = create(:user, client: client, role: :client, active: true, first_time_login: false)
      other = build(:order, client: client, catalog: catalog, status: :cart, ordered_by: other_user)
      other.order_items = [ build(:order_item, order: other, product: product, quantity: 10) ]
      other.save!
      file = other.drive_files.create!(drive_file_id: "x", filename: "a.png", mime_type: "image/png")

      expect {
        delete checkout_attachment_path(file), headers: headers
      }.not_to change { DriveFile.count }
    end
  end
end
