require 'rails_helper'

RSpec.describe "Admin::Orders#mark_as_received", type: :request do
  let(:admin) { create(:user, role: "admin") }
  let(:order) { create(:order, :with_catalog_line_items, status: :processing) }

  before { sign_in admin }

  it "marks a processing order as received without recording a receiver" do
    post mark_as_received_admin_order_path(order)

    expect(response).to redirect_to(admin_order_path(order))
    order.reload
    expect(order).to be_status_received
    expect(order.received_at).to be_present
    expect(order.received_by).to be_nil
  end

  it "rejects orders of clients with inventory enabled" do
    order.client.update!(inventory_enabled: true)

    post mark_as_received_admin_order_path(order)

    expect(flash[:alert]).to match(/received on the client side/)
    expect(order.reload).to be_status_processing
    expect(order.received_at).to be_nil
  end

  it "rejects an already received order" do
    order.update!(status: :received, received_at: 1.day.ago)

    post mark_as_received_admin_order_path(order)

    expect(flash[:alert]).to eq("Order already received")
  end
end
