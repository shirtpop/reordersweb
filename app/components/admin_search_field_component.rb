# frozen_string_literal: true

class AdminSearchFieldComponent < ViewComponent::Base
  def initialize(form_url:, placeholder: "Search by name...", method: :get)
    @form_url = form_url
    @placeholder = placeholder
    @method = method
  end
end
