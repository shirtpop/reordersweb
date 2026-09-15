require 'rails_helper'

RSpec.describe Notification, type: :model do
  let(:client) { create(:client, :without_users) }
  let(:recipient) { create(:user, :client, client: client) }
  let(:order) { create(:order, :with_catalog_line_items, client: client) }

  def build_notification(**attrs)
    build(:notification, recipient: recipient, notifiable: order, **attrs)
  end

  describe 'validations' do
    it { expect(build_notification).to be_valid }
    it { expect(build_notification(title: nil)).not_to be_valid }
  end

  describe 'scopes' do
    it 'separates read and unread notifications' do
      unread = create(:notification, recipient: recipient, notifiable: order)
      read = create(:notification, recipient: recipient, notifiable: order, read_at: 1.hour.ago)

      aggregate_failures do
        expect(described_class.unread).to contain_exactly(unread)
        expect(described_class.read).to contain_exactly(read)
      end
    end

    it 'only considers read notifications older than the retention window as expired' do
      stale = create(:notification, recipient: recipient, notifiable: order, read_at: 4.days.ago)
      fresh = create(:notification, recipient: recipient, notifiable: order, read_at: 1.hour.ago)
      create(:notification, recipient: recipient, notifiable: order, read_at: nil)

      expect(described_class.expired_read).to contain_exactly(stale)
      expect(described_class.expired_read).not_to include(fresh)
    end
  end

  describe '.prune_expired_read!' do
    it 'deletes only expired read notifications' do
      stale = create(:notification, recipient: recipient, notifiable: order, read_at: 4.days.ago)
      fresh = create(:notification, recipient: recipient, notifiable: order, read_at: 1.hour.ago)

      described_class.prune_expired_read!

      aggregate_failures do
        expect(described_class.exists?(stale.id)).to be false
        expect(described_class.exists?(fresh.id)).to be true
      end
    end
  end

  describe '#read?' do
    it { expect(build_notification(read_at: nil).read?).to be false }
    it { expect(build_notification(read_at: Time.current).read?).to be true }
  end
end
