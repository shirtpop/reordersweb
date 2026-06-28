require 'rails_helper'

RSpec.describe Products::Duplicator do
  let!(:product) { create(:product, :with_colors) }
  subject(:duplicator) { described_class.new(product: product) }

  describe "#call!" do
    context "when google drive operations succeed" do
      before do
        allow_any_instance_of(GoogleDrive::Copier).to receive(:call!)
      end

      it "creates a new product" do
        expect { duplicator.call! }.to change(Product, :count).by(1)
      end

      it "names the duplicate with 'Copy of' prefix" do
        new_product = duplicator.call!
        expect(new_product.name).to eq("Copy of #{product.name}")
      end

      it "returns a persisted product" do
        new_product = duplicator.call!
        expect(new_product).to be_persisted
      end

      it "duplicates all product colors" do
        new_product = duplicator.call!
        expect(new_product.product_colors.count).to eq(product.product_colors.count)
      end

      it "does not raise a validation error for missing product colors" do
        expect { duplicator.call! }.not_to raise_error
      end

      it "copies color attributes to the duplicate" do
        new_product = duplicator.call!
        original_names = product.product_colors.pluck(:name).sort
        duplicate_names = new_product.product_colors.pluck(:name).sort
        expect(duplicate_names).to eq(original_names)
      end
    end

    context "when GoogleDrive::Copier raises CopyError" do
      it "raises DuplicateError" do
        p = create(:product, :with_colors)
        create(:drive_file, attachable: p, drive_file_id: "abc123", mime_type: "image/jpeg")
        # Reload to clear the stale drive_files cache from the product's save! validation.
        # HasDriveFiles#validate_max_drive_files loads drive_files during save, caching [].
        # The drive file created above won't be visible without a reload.
        p.reload
        allow_any_instance_of(GoogleDrive::Copier).to receive(:call!)
          .and_raise(GoogleDrive::Copier::CopyError, "drive error")

        expect { described_class.new(product: p).call! }.to raise_error(Products::Duplicator::DuplicateError, "drive error")
      end
    end
  end
end
