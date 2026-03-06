# frozen_string_literal: true

module Admin
  class OnboardingChecklistComponent < ViewComponent::Base
    STEPS = [
      { key: :client_created, label: "Client created" },
      { key: :billing_address, label: "Billing address set" },
      { key: :shipping_address, label: "Shipping address set" },
      { key: :user_created, label: "User account created" },
      { key: :products_assigned, label: "Products assigned" },
      { key: :catalog_active, label: "Catalog activated" }
    ].freeze

    def initialize(client:)
      @client = client
      @steps = client.setup_steps
      @progress = client.setup_progress
    end

    def steps_with_status
      STEPS.map { |step| step.merge(done: @steps[step[:key]]) }
    end

    def completed_count
      @steps.values.count(true)
    end

    def total_count
      @steps.size
    end

    def all_complete?
      @progress == 100
    end
  end
end
