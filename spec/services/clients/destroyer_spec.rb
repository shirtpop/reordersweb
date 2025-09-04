require 'rails_helper'

RSpec.describe Clients::Destroyer do
  let!(:client) { create(:client) }
  subject(:destroyer) { described_class.new(client: client) }

  describe "#call!" do
    context "when client is successfully destroyed" do
      it "destroys the client" do
        expect {
          destroyer.call!
        }.to change(Client, :count).by(-1)
      end
    end

    context "when ActiveRecord::RecordNotFound is raised" do
      before do
        allow(client).to receive(:destroy!).and_raise(ActiveRecord::RecordNotFound, "not found")
      end

      it "raises Clients::Destroyer::DeleteError with message" do
        expect {
          destroyer.call!
        }.to raise_error(Clients::Destroyer::DeleteError, /Failed to delete client or associated drive files: not found/)
      end
    end

    context "when GoogleDrive::Errors::DeleteError is raised" do
      before do
        allow(client).to receive(:destroy!).and_raise(GoogleDrive::Errors::DeleteError, "drive error")
      end

      it "raises Clients::Destroyer::DeleteError with message" do
        expect {
          destroyer.call!
        }.to raise_error(Clients::Destroyer::DeleteError, /Failed to delete client or associated drive files: drive error/)
      end
    end
  end
end
