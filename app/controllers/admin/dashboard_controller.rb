module Admin
  class DashboardController < BaseController
    def index
      # Time boundaries
      @today = Date.current
      @yesterday = @today - 1.day
      @week_start = @today.beginning_of_week
      @last_week_start = @week_start - 1.week
      @last_week_end = @week_start - 1.day
      @thirty_days_ago = @today - 30.days

      # Daily trend data for chart (last 30 days)
      @daily_order_counts = calculate_daily_order_counts(@thirty_days_ago, @today)

      # Comparison metrics
      @orders_today = submitted_orders.where(created_at: @today.beginning_of_day..@today.end_of_day).count
      @orders_yesterday = submitted_orders.where(created_at: @yesterday.beginning_of_day..@yesterday.end_of_day).count
      @orders_this_week = submitted_orders.where(created_at: @week_start.beginning_of_day..@today.end_of_day).count
      @orders_last_week = submitted_orders.where(created_at: @last_week_start.beginning_of_day..@last_week_end.end_of_day).count

      # Status-based metrics
      @orders_by_status = calculate_orders_by_status
      @pending_fulfillment_count = Order.where(status: [ "submitted", "processing" ]).count

      # Recent orders (expanded to 12)
      @recent_orders = Order.where.not(status: "cart")
                            .includes(:client, :catalog)
                            .order(created_at: :desc)
                            .limit(12)

      # Keep existing pending receipt alert
      @pending_receipt_orders = Order.pending_receipt
                                    .includes(:client)
                                    .order(delivery_date: :asc)
                                    .limit(20)
    end

    def chart_data
      days = params[:days].to_i
      days = 30 if days <= 0 || days > 365 # Default and max validation

      today = Date.current
      start_date = today - days.days

      data = calculate_daily_order_counts(start_date, today)

      render json: data
    end

    private

    def submitted_orders
      Order.submitted
    end

    def calculate_daily_order_counts(start_date, end_date)
      counts = submitted_orders
        .where(created_at: start_date.beginning_of_day..end_date.end_of_day)
        .group("DATE(created_at)")
        .count

      # Fill in missing dates with 0
      (start_date..end_date).each_with_object({}) do |date, hash|
        hash[date.to_s] = counts[date] || 0
      end
    end

    def calculate_orders_by_status
      submitted_orders.group(:status).count
    end
  end
end
