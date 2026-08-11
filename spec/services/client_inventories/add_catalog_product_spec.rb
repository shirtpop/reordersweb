require 'rails_helper'

RSpec.describe ClientInventories::AddCatalogProduct do
  let(:client) { create(:client) }
  let(:user) { create(:user, :client, client: client) }
  let(:catalog) { create(:catalog, client: client, status: 'active') }
  let(:product) do
    create(:product, sizes: [ "M", "L" ], product_colors: [ build(:product_color, name: "Red", minimum_order: 0) ])
  end

  let(:variants_params) do
    {
      "0" => { color: "Red", size: "M", quantity: "3" },
      "1" => { color: "Red", size: "L", quantity: "5" }
    }
  end

  before do
    create(:catalogs_product, catalog: catalog, product: product)
  end

  subject(:call!) do
    described_class.call!(client: client, user: user, product_id: product.id, variants_params: variants_params)
  end

  describe ".call!" do
    context "when the product is assigned to the client and there is at least one valid variant" do
      it "creates a Client::Product for the client" do
        expect { call! }.to change { client.client_products.count }.by(1)

        client_product = client.client_products.last
        expect(client_product.product_id).to eq(product.id)
        expect(client_product.name).to eq(product.name)
      end

      it "creates a variant, inventory, and add movement for each valid entry" do
        expect { call! }.to change { Client::ProductVariant.count }.by(2)
          .and change { Client::Inventory.count }.by(2)
          .and change { Client::InventoryMovement.count }.by(2)
      end

      it "sets the correct attributes on the created variants, inventories, and movements" do
        call!
        client_product = client.client_products.last

        variant_m = client_product.product_variants.find_by(color: "Red", size: "M")
        expect(variant_m).to be_present
        expect(variant_m.inventory.quantity).to eq(3)
        expect(variant_m.inventory.client).to eq(client)

        movement_m = variant_m.inventory.inventory_movements.last
        expect(movement_m.user).to eq(user)
        expect(movement_m).to be_add
        expect(movement_m.quantity).to eq(3)

        variant_l = client_product.product_variants.find_by(color: "Red", size: "L")
        expect(variant_l.inventory.quantity).to eq(5)
      end

      it "returns the created Client::Product" do
        result = call!
        expect(result).to be_a(Client::Product)
        expect(result.product_id).to eq(product.id)
      end

      context "when one entry has a zero quantity and another is valid" do
        let(:variants_params) do
          {
            "0" => { color: "Red", size: "M", quantity: "0" },
            "1" => { color: "Red", size: "L", quantity: "5" }
          }
        end

        it "skips creating a variant/inventory for the zero-quantity entry" do
          call!
          client_product = client.client_products.last

          expect(client_product.product_variants.count).to eq(1)
          expect(client_product.product_variants.find_by(color: "Red", size: "M")).to be_nil
        end
      end

      context "when one entry has a negative quantity and another is valid" do
        let(:variants_params) do
          {
            "0" => { color: "Red", size: "M", quantity: "-2" },
            "1" => { color: "Red", size: "L", quantity: "5" }
          }
        end

        it "skips creating a variant/inventory for the negative-quantity entry" do
          call!
          client_product = client.client_products.last

          expect(client_product.product_variants.count).to eq(1)
        end
      end

      context "when one entry has a color not offered by the product" do
        let(:variants_params) do
          {
            "0" => { color: "Blue", size: "M", quantity: "3" },
            "1" => { color: "Red", size: "L", quantity: "5" }
          }
        end

        it "skips the entry with the unavailable color" do
          call!
          client_product = client.client_products.last

          expect(client_product.product_variants.count).to eq(1)
          expect(client_product.product_variants.find_by(color: "Blue")).to be_nil
        end
      end

      context "when one entry has a size not offered by the product" do
        let(:variants_params) do
          {
            "0" => { color: "Red", size: "XL", quantity: "3" },
            "1" => { color: "Red", size: "L", quantity: "5" }
          }
        end

        it "skips the entry with the unavailable size" do
          call!
          client_product = client.client_products.last

          expect(client_product.product_variants.count).to eq(1)
          expect(client_product.product_variants.find_by(size: "XL")).to be_nil
        end
      end
    end

    context "when no entry has a positive quantity" do
      let(:variants_params) do
        {
          "0" => { color: "Red", size: "M", quantity: "0" },
          "1" => { color: "Red", size: "L", quantity: "-1" }
        }
      end

      it "raises NoQuantityError" do
        expect { call! }.to raise_error(described_class::NoQuantityError)
      end

      it "does not create a Client::Product" do
        expect {
          begin
            call!
          rescue described_class::NoQuantityError
            nil
          end
        }.not_to change { Client::Product.count }
      end
    end

    context "when variants_params is empty" do
      let(:variants_params) { {} }

      it "raises NoQuantityError" do
        expect { call! }.to raise_error(described_class::NoQuantityError)
      end
    end

    context "when no entry matches an available color/size" do
      let(:variants_params) do
        { "0" => { color: "Blue", size: "XL", quantity: "3" } }
      end

      it "raises NoQuantityError" do
        expect { call! }.to raise_error(described_class::NoQuantityError)
      end
    end

    context "when the product is not assigned to the client" do
      let(:unassigned_product) { create(:product) }

      subject(:call!) do
        described_class.call!(client: client, user: user, product_id: unassigned_product.id, variants_params: variants_params)
      end

      it "raises NotAssignedError" do
        expect { call! }.to raise_error(described_class::NotAssignedError)
      end

      it "does not create a Client::Product" do
        expect {
          begin
            call!
          rescue described_class::NotAssignedError
            nil
          end
        }.not_to change { Client::Product.count }
      end
    end

    context "when the product is only assigned via an archived catalog" do
      before { catalog.update!(status: :archived) }

      it "raises NotAssignedError" do
        expect { call! }.to raise_error(described_class::NotAssignedError)
      end
    end

    context "when the product is assigned to a different client's catalog" do
      let(:other_client) { create(:client) }
      let(:other_catalog) { create(:catalog, client: other_client, status: 'active') }

      subject(:call!) do
        described_class.call!(client: other_client, user: user, product_id: product.id, variants_params: variants_params)
      end

      it "raises NotAssignedError because the product is not in the other client's catalogs" do
        expect { call! }.to raise_error(described_class::NotAssignedError)
      end
    end

    context "when a Client::Product already exists for this client and product (model validation)" do
      before { create(:client_product, client: client, admin_product: product) }

      it "raises AlreadyAddedError" do
        expect { call! }.to raise_error(described_class::AlreadyAddedError)
      end

      it "does not create any additional variants, inventories, or movements" do
        expect {
          begin
            call!
          rescue described_class::AlreadyAddedError
            nil
          end
        }.not_to change { Client::ProductVariant.count }
      end
    end

    context "when the underlying create! raises ActiveRecord::RecordNotUnique" do
      before do
        allow(client.client_products).to receive(:create!).and_raise(ActiveRecord::RecordNotUnique.new("duplicate key"))
      end

      it "raises AlreadyAddedError" do
        expect { call! }.to raise_error(described_class::AlreadyAddedError)
      end
    end

    context "when create_client_product! raises a RecordInvalid unrelated to product_id" do
      before do
        allow(client.client_products).to receive(:create!).and_raise(
          ActiveRecord::RecordInvalid.new(Client::Product.new.tap { |p| p.errors.add(:name, "can't be blank") })
        )
      end

      it "re-raises the original error instead of AlreadyAddedError" do
        expect { call! }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context "when creating an inventory record fails partway through" do
      before do
        call_count = 0
        allow(Client::Inventory).to receive(:create!) do |*args, **kwargs|
          call_count += 1
          raise "boom" if call_count == 2

          Client::Inventory.new(*args, **kwargs).tap(&:save!)
        end
      end

      it "raises the underlying error" do
        expect { call! }.to raise_error("boom")
      end

      it "rolls back the whole transaction, including the Client::Product and the already-created variant" do
        expect {
          begin
            call!
          rescue RuntimeError
            nil
          end
        }.not_to change { Client::Product.count }
      end

      it "does not leave any variants persisted" do
        expect {
          begin
            call!
          rescue RuntimeError
            nil
          end
        }.not_to change { Client::ProductVariant.count }
      end
    end
  end
end
