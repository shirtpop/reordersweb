require 'rails_helper'

RSpec.describe Orders::MinimumOrderValidator do
  Item = Orders::MinimumOrderValidator::Item

  def make_color(name:, minimum_order:)
    instance_double(ProductColor, name: name, minimum_order: minimum_order)
  end

  def make_product(name: 'Test Shirt', minimum_order:, colors:)
    instance_double(Product, name: name, minimum_order: minimum_order, product_colors: colors)
  end

  def item(product:, color:, quantity:)
    Item.new(product, color, quantity)
  end

  subject(:validator) { described_class.new(order_items: items) }

  describe '#valid? / #violations' do
    context 'with a single required color meeting its minimum' do
      let(:red) { make_color(name: 'Red', minimum_order: 12) }
      let(:product) { make_product(minimum_order: 12, colors: [red]) }
      let(:items) { [item(product: product, color: 'Red', quantity: 12)] }

      it { is_expected.to be_valid }
      it { expect(validator.violations).to be_empty }
    end

    context 'when a required color is below its minimum' do
      let(:red) { make_color(name: 'Red', minimum_order: 12) }
      let(:product) { make_product(minimum_order: 12, colors: [red]) }
      let(:items) { [item(product: product, color: 'Red', quantity: 5)] }

      it { is_expected.not_to be_valid }

      it 'includes the color name, minimum, and selected quantity in the violation' do
        expect(validator.violations.first).to include('Red', '12', '5 selected')
      end
    end

    context 'when a required color has zero quantity' do
      let(:red) { make_color(name: 'Red', minimum_order: 12) }
      let(:product) { make_product(minimum_order: 12, colors: [red]) }
      let(:items) { [item(product: product, color: 'Red', quantity: 0)] }

      it { is_expected.not_to be_valid }
    end

    context 'when quantities are split across sizes (summed per color)' do
      let(:red) { make_color(name: 'Red', minimum_order: 12) }
      let(:product) { make_product(minimum_order: 12, colors: [red]) }
      let(:items) do
        [
          item(product: product, color: 'Red', quantity: 6),
          item(product: product, color: 'Red', quantity: 6)
        ]
      end

      it 'sums quantities for the same color and passes' do
        is_expected.to be_valid
      end
    end

    context 'with an optional color (minimum_order 0) not ordered' do
      let(:red) { make_color(name: 'Red', minimum_order: 12) }
      let(:blue) { make_color(name: 'Blue', minimum_order: 0) }
      let(:product) { make_product(minimum_order: 12, colors: [red, blue]) }
      let(:items) { [item(product: product, color: 'Red', quantity: 12)] }

      it 'does not flag the unordered optional color' do
        is_expected.to be_valid
      end
    end

    context 'with an optional color ordered below the product run size' do
      let(:red) { make_color(name: 'Red', minimum_order: 12) }
      let(:blue) { make_color(name: 'Blue', minimum_order: 0) }
      let(:product) { make_product(minimum_order: 12, colors: [red, blue]) }
      let(:items) do
        [
          item(product: product, color: 'Red', quantity: 12),
          item(product: product, color: 'Blue', quantity: 3)
        ]
      end

      it { is_expected.not_to be_valid }

      it 'flags the optional color with the product minimum' do
        violation = validator.violations.find { |v| v.include?('Blue') }
        expect(violation).to include('minimum per color is 12')
      end
    end

    context 'when total quantity is below the product minimum (transition period)' do
      let(:red) { make_color(name: 'Red', minimum_order: 0) }
      let(:product) { make_product(minimum_order: 12, colors: [red]) }
      let(:items) { [item(product: product, color: 'Red', quantity: 5)] }

      it { is_expected.not_to be_valid }

      it 'flags the total with the product minimum' do
        violation = validator.violations.find { |v| v.include?('total minimum') }
        expect(violation).to include('12', '5 selected')
      end
    end

    context 'with multiple products in the order' do
      let(:red) { make_color(name: 'Red', minimum_order: 12) }
      let(:product_a) { make_product(name: 'Shirt A', minimum_order: 12, colors: [red]) }

      let(:green) { make_color(name: 'Green', minimum_order: 6) }
      let(:product_b) { make_product(name: 'Shirt B', minimum_order: 6, colors: [green]) }

      let(:items) do
        [
          item(product: product_a, color: 'Red', quantity: 12),
          item(product: product_b, color: 'Green', quantity: 3)
        ]
      end

      it 'validates each product independently and reports only the failing one' do
        violations = validator.violations
        expect(violations).to be_one
        expect(violations.first).to include('Shirt B', 'Green')
      end
    end

    context 'with no items' do
      let(:items) { [] }

      it { is_expected.to be_valid }
    end
  end
end
