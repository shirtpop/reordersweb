# frozen_string_literal: true

module Notifications
  class Base
    def initialize(notifiable)
      @notifiable = notifiable
    end

    def call
      return unless recipients?

      recipients.find_each do |user|
        Notification.create!(
          recipient: user,
          notifiable: notifiable,
          kind: kind,
          title: title,
          description: description
        )
      end
    end

    private

    attr_reader :notifiable

    def recipients?
      recipients.exists?
    end

    def recipients
      raise NotImplementedError, "#{self.class} must implement #recipients"
    end

    def kind
      raise NotImplementedError, "#{self.class} must implement #kind"
    end

    def title
      raise NotImplementedError, "#{self.class} must implement #title"
    end

    def description
      raise NotImplementedError, "#{self.class} must implement #description"
    end
  end
end
