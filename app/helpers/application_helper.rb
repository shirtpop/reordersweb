module ApplicationHelper
  include Pagy::Frontend

  INVENTORIES_CONTROLLER = [ "inventories", "inventory_movements" ]

  def client_inventory_enabled?
    @current_client.inventory_enabled
  end

  def inventories_controller?
    INVENTORIES_CONTROLLER.include?(controller_name)
  end
end
