class NotificationsController < BaseController
  def index
    @pagy, @notifications = pagy(current_user.notifications.recent_first)
  end

  def mark_all_read
    current_user.notifications.unread.update_all(read_at: Time.current)
    Notification.broadcast_unread_count_for(current_user)
    head :no_content
  end
end
