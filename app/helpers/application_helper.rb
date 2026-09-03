module ApplicationHelper
  include Pagy::Frontend

  INVENTORIES_CONTROLLER = [ "inventories", "inventory_movements" ]

  def client_inventory_enabled?
    return false unless @current_client

    @current_client.inventory_enabled
  end

  def inventories_controller?
    INVENTORIES_CONTROLLER.include?(controller_name)
  end

  def inventory_app?
    request.path.start_with?("/inventories")
  end

  # The sort_by value a "click to sort" link on this column should point to next:
  # toggles asc/desc if this column is already the active sort, otherwise starts at asc.
  def toggle_sort(sort_key)
    params[:sort_by] == "#{sort_key}_asc" ? "#{sort_key}_desc" : "#{sort_key}_asc"
  end

  # A sortable <th> label: the column name linked to `url` (built by the caller, e.g.
  # `products_path(sort_by: toggle_sort("name"), q: params[:q])`), with an up/down/neutral
  # arrow reflecting whether `sort_key` is the currently active sort_by column.
  def sortable_column_header(label, url, sort_key)
    link_to url, class: "group inline-flex items-center gap-1 text-gray-700 hover:text-pink-700", data: { turbo_frame: "tab-content" } do
      safe_join([ label, sort_direction_icon(sort_key) ])
    end
  end

  def sort_direction_icon(sort_key)
    path_d = case params[:sort_by]
    when "#{sort_key}_asc" then "M5 15l7-7 7 7"
    when "#{sort_key}_desc" then "M19 9l-7 7-7-7"
    else "M7 16V4m0 0L3 8m4-4l4 4m6 0v12m0 0l4-4m-4 4l-4-4"
    end

    content_tag(:svg, class: "h-4 w-4 text-gray-400 group-hover:text-pink-500", fill: "none", stroke: "currentColor", viewBox: "0 0 24 24", "aria-hidden": "true") do
      content_tag(:path, nil, "stroke-linecap": "round", "stroke-linejoin": "round", "stroke-width": "2", d: path_d)
    end
  end
end
