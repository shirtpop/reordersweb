# spec/components/admin_search_field_component_spec.rb
require "rails_helper"

RSpec.describe AdminSearchFieldComponent, type: :component do
  let(:form_url) { "/admin/clients" }
  let(:placeholder) { "Search by name..." }
  let(:method) { :get }

  describe "rendering" do
    before do
      render_inline(described_class.new(form_url: form_url, placeholder: placeholder, method: method))
    end

    it "renders the search form with correct URL" do
      expect(rendered_content).to include("action=\"#{form_url}\"")
      expect(rendered_content).to include("method=\"get\"")
    end

    it "renders the search input field" do
      expect(rendered_content).to include("type=\"text\"")
      expect(rendered_content).to include("name=\"q\"")
    end

    it "renders the search icon" do
      expect(rendered_content).to include("svg")
    end

    it "uses the correct placeholder text" do
      expect(rendered_content).to include("placeholder=\"#{placeholder}\"")
    end

    it "has auto-search stimulus controller" do
      expect(rendered_content).to include("data-controller=\"auto-search\"")
    end

    it "has correct stimulus targets" do
      expect(rendered_content).to include("data-auto-search-target=\"form\"")
      expect(rendered_content).to include("data-auto-search-target=\"input\"")
    end

    it "has correct stimulus action" do
      expect(rendered_content).to include("data-action=\"input-&gt;auto-search#search\"")
    end
  end

  describe "with custom parameters" do
    it "uses custom placeholder" do
      render_inline(described_class.new(form_url: form_url, placeholder: "Custom search"))
      expect(rendered_content).to include("placeholder=\"Custom search\"")
    end

    it "uses custom method" do
      render_inline(described_class.new(form_url: form_url, method: :post))
      expect(rendered_content).to include("method=\"post\"")
    end
  end
end
