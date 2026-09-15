require 'rails_helper'

RSpec.describe Notifications::Base, type: :service do
  let(:client) { create(:client, :without_users) }
  let(:order) { create(:order, :with_catalog_line_items, client: client) }

  def notifier_class(recipients:, kind: "order_processed", title: "Title", description: "Description")
    Class.new(described_class) do
      define_method(:recipients) { recipients }
      define_method(:kind) { kind }
      define_method(:title) { title }
      define_method(:description) { description }
    end
  end

  describe '#call' do
    it 'creates a notification for each recipient' do
      user = create(:user, :client, client: client, active: true)
      klass = notifier_class(recipients: User.where(id: user.id))

      expect { klass.new(order).call }.to change { user.notifications.count }.by(1)

      notification = user.notifications.last
      aggregate_failures do
        expect(notification.notifiable).to eq(order)
        expect(notification.title).to eq("Title")
        expect(notification.description).to eq("Description")
      end
    end

    it 'does nothing when there are no recipients' do
      klass = notifier_class(recipients: User.none)

      expect { klass.new(order).call }.not_to change(Notification, :count)
    end
  end

  describe 'unimplemented template methods' do
    subject(:notifier) { described_class.new(order) }

    it 'raises for #recipients' do
      expect { notifier.send(:recipients) }.to raise_error(NotImplementedError)
    end

    it 'raises for #kind' do
      expect { notifier.send(:kind) }.to raise_error(NotImplementedError)
    end

    it 'raises for #title' do
      expect { notifier.send(:title) }.to raise_error(NotImplementedError)
    end

    it 'raises for #description' do
      expect { notifier.send(:description) }.to raise_error(NotImplementedError)
    end
  end
end
