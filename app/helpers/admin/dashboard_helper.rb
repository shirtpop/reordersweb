# frozen_string_literal: true

module Admin
  module DashboardHelper
    def calculate_percent_change(previous, current)
      return 0 if previous.zero?

      ((current - previous).to_f / previous * 100).round(1)
    end

    def status_badge_class(status)
      case status.to_s
      when "submitted"
        "bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-300"
      when "processing"
        "bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-300"
      when "received"
        "bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300"
      when "cancelled"
        "bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-300"
      else
        "bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-300"
      end
    end

    def comparison_indicator(current, previous)
      change = current - previous
      return { icon: "→", class: "text-gray-500", text: "No change" } if change.zero?

      if change.positive?
        { icon: "↑", class: "text-green-600 dark:text-green-400", text: "+#{change}" }
      else
        { icon: "↓", class: "text-red-600 dark:text-red-400", text: change.to_s }
      end
    end

    def format_date_short(date)
      return "N/A" if date.blank?

      date.strftime("%b %d, %Y")
    end
  end
end
