require 'rails_helper'

RSpec.describe Products::Destroyer do
  let!(:product) { create(:product) }
  subject(:destroyer) { described_class.new(product: product) }

  describe "#call!" do
    context "when product is successfully destroyed" do
      it "destroys the product" do
        expect {
          destroyer.call!
        }.to change(Product, :count).by(-1)
      end
    end

    context "when ActiveRecord::RecordNotFound is raised" do
      before do
        allow(product).to receive(:destroy!).and_raise(ActiveRecord::RecordNotFound, "not found")
      end

      it "raises Products::Destroyer::DeleteError with message" do
        expect {
          destroyer.call!
        }.to raise_error(Products::Destroyer::DeleteError, /Failed to delete product or associated drive files: not found/)
      end
    end

    context "when GoogleDrive::Errors::DeleteError is raised" do
      before do
        allow(product).to receive(:destroy!).and_raise(GoogleDrive::Errors::DeleteError, "drive error")
      end

      it "raises Products::Destroyer::DeleteError with message" do
        expect {
          destroyer.call!
        }.to raise_error(Products::Destroyer::DeleteError, /Failed to delete product or associated drive files: drive error/)
      end
    end
  end
end
