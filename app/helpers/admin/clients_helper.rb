module Admin::ClientsHelper
  def addresses_same?(address1, address2)
    return false if address1.nil? || address2.nil?
    
    address1.street == address2.street &&
    address1.city == address2.city &&
    address1.state == address2.state &&
    address1.zip_code == address2.zip_code
  end

  def field_error_class(object, field, base_class = 'border-gray-300')
    if object&.errors&.[](field)&.any?
      base_class.gsub('border-gray-300', 'border-red-500')
    else
      base_class
    end
  end

  def display_field_errors(object, field)
    return unless object&.errors&.[](field)&.any?
    
    content_tag :p, class: "mt-1 text-sm text-red-600" do
      object.errors[field].first
    end
  end
end