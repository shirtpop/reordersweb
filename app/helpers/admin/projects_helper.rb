module Admin::ProjectsHelper
  def status_badge_class(status)
    case status.to_s
    when "draft"
      "bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-300"
    when "active"
      "bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300"
    when "archived"
      "bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-300"
    else
      "bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-300"
    end
  end
end
