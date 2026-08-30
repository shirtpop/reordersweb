# spec/components/storefront/catalog_sidebar_component_spec.rb
require "rails_helper"

RSpec.describe Storefront::CatalogSidebarComponent, type: :component do
  # create(:client)'s default `users { [ association(:user) ] }` currently fails against
  # User's admin_cannot_belong_to_client validation (pre-existing, unrelated to this spec) —
  # :without_users sidesteps it so these examples exercise real persisted records.
  let(:client) { create(:client, :without_users) }

  def link_html_for(name)
    rendered_content[/<a[^>]*>#{Regexp.escape(name)}<\/a>/]
  end

  describe "rendering" do
    it "renders nothing when the client has only one catalog" do
      catalog = create(:catalog, client: client, status: :active)

      render_inline(described_class.new(catalogs: [ catalog ], selected_catalog: catalog, current_client: client))

      expect(rendered_content.strip).to be_empty
    end

    it "renders a flat list of catalogs when the client has no linked children" do
      first_catalog = create(:catalog, client: client, name: "First Catalog", status: :active)
      second_catalog = create(:catalog, client: client, name: "Second Catalog", status: :active)

      render_inline(described_class.new(catalogs: [ first_catalog, second_catalog ], selected_catalog: first_catalog, current_client: client))

      expect(rendered_content).to include("First Catalog")
      expect(rendered_content).to include("Second Catalog")
      expect(rendered_content).not_to include("(Main)")
    end

    it "highlights the selected catalog and not the others" do
      first_catalog = create(:catalog, client: client, name: "First Catalog", status: :active)
      second_catalog = create(:catalog, client: client, name: "Second Catalog", status: :active)

      render_inline(described_class.new(catalogs: [ first_catalog, second_catalog ], selected_catalog: second_catalog, current_client: client))

      expect(link_html_for("Second Catalog")).to include("bg-gradient-to-r")
      expect(link_html_for("First Catalog")).not_to include("bg-gradient-to-r")
    end

    it "groups catalogs by owning business when the client has linked children" do
      child = create(:client, :without_users, parent: client)
      own_catalog = create(:catalog, client: client, name: "Main Catalog", status: :active)
      child_catalog = create(:catalog, client: child, name: "Child Catalog", status: :active)

      render_inline(described_class.new(catalogs: [ own_catalog, child_catalog ], selected_catalog: own_catalog, current_client: client))

      expect(rendered_content).to include("#{client.company_name} (Main)")
      expect(rendered_content).to include(child.company_name)
      expect(rendered_content).to include("Main Catalog")
      expect(rendered_content).to include("Child Catalog")
    end
  end
end
