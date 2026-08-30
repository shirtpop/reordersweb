# frozen_string_literal: true

module Storefront
  class CatalogSidebarComponent < ViewComponent::Base
    def initialize(catalogs:, selected_catalog:, current_client:)
      @catalogs = catalogs
      @selected_catalog = selected_catalog
      @current_client = current_client
    end

    def render?
      @catalogs.size > 1
    end

    # Grouped by owning business, main account first — nil when the client has no
    # linked children, so the sidebar falls back to one flat list.
    def catalog_groups
      return @catalog_groups if defined?(@catalog_groups)

      children = @current_client.children.to_a
      @catalog_groups = if children.empty?
        nil
      else
        catalogs_by_owner_id = @catalogs.group_by(&:client_id)
        ([ @current_client ] + children).filter_map do |owner|
          owner_catalogs = catalogs_by_owner_id[owner.id]
          [ owner, owner_catalogs ] if owner_catalogs.present?
        end
      end
    end

    def owner_label(owner)
      owner == @current_client ? "#{owner.company_name} (Main)" : owner.company_name
    end

    def selected?(catalog)
      @selected_catalog.id == catalog.id
    end

    def catalog_link_class(catalog)
      base = "block px-4 py-2.5 rounded-lg text-sm font-medium transition-all duration-200"
      return "#{base} bg-gradient-to-r from-pink-600 to-rose-600 text-white shadow-md" if selected?(catalog)

      "#{base} text-gray-700 hover:bg-gray-100"
    end
  end
end
