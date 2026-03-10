# frozen_string_literal: true

module Admin
  class MetricCardComponent < ViewComponent::Base
    def initialize(title:, value:, comparison: nil, color: "blue", icon: nil)
      @title = title
      @value = value
      @comparison = comparison # { previous: 5, change: +3, percent: 60.0 }
      @color = color # "blue", "green", "amber", "purple"
      @icon = icon
    end

    def color_classes
      case @color
      when "blue"
        "bg-blue-100 dark:bg-blue-900"
      when "green"
        "bg-green-100 dark:bg-green-900"
      when "amber"
        "bg-amber-100 dark:bg-amber-900"
      when "purple"
        "bg-purple-100 dark:bg-purple-900"
      else
        "bg-gray-100 dark:bg-gray-700"
      end
    end

    def icon_color_classes
      case @color
      when "blue"
        "text-blue-500 dark:text-blue-300"
      when "green"
        "text-green-500 dark:text-green-300"
      when "amber"
        "text-amber-500 dark:text-amber-300"
      when "purple"
        "text-purple-500 dark:text-purple-300"
      else
        "text-gray-500 dark:text-gray-300"
      end
    end

    def comparison_text
      return nil unless @comparison

      change = @comparison[:change]
      percent = @comparison[:percent]

      if change.zero?
        "No change"
      elsif change.positive?
        "+#{change} (↑#{percent.abs}%)"
      else
        "#{change} (↓#{percent.abs}%)"
      end
    end

    def comparison_class
      return "" unless @comparison

      change = @comparison[:change]
      if change.zero?
        "text-gray-500 dark:text-gray-400"
      elsif change.positive?
        "text-green-600 dark:text-green-400"
      else
        "text-red-600 dark:text-red-400"
      end
    end

    def has_comparison?
      @comparison.present?
    end
  end
end
