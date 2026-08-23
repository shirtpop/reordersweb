module Orders
  class CrossBusinessCartError < StandardError
    attr_reader :client

    def initialize(client)
      @client = client
      super("You already have items in your cart for #{client.company_name}. Please check out or clear that cart before ordering for a different business.")
    end
  end
end
