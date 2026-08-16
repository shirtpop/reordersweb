require 'rails_helper'

RSpec.describe GoogleDrive::DriveService do
  describe ".delete_file" do
    let(:drive_service) { instance_double(Google::Apis::DriveV3::DriveService) }

    before do
      allow(described_class).to receive(:drive_service).and_return(drive_service)
    end

    context "when the file is already gone from Drive (404)" do
      before do
        allow(drive_service).to receive(:delete_file).and_raise(
          Google::Apis::ClientError.new("notFound: File not found: abc123.", status_code: 404)
        )
      end

      it "does not raise" do
        expect { described_class.delete_file("abc123") }.not_to raise_error
      end
    end

    context "when Drive rejects the request for another client reason (e.g. 400)" do
      before do
        allow(drive_service).to receive(:delete_file).and_raise(
          Google::Apis::ClientError.new("invalid: Bad request.", status_code: 400)
        )
      end

      it "raises GoogleDrive::Errors::DeleteError" do
        expect { described_class.delete_file("abc123") }.to raise_error(GoogleDrive::Errors::DeleteError, /Bad request/)
      end
    end

    context "when Drive has a server error" do
      before do
        allow(drive_service).to receive(:delete_file).and_raise(
          Google::Apis::ServerError.new("Internal error.", status_code: 500)
        )
      end

      it "raises GoogleDrive::Errors::DeleteError" do
        expect { described_class.delete_file("abc123") }.to raise_error(GoogleDrive::Errors::DeleteError, /Internal error/)
      end
    end

    context "when authorization fails" do
      before do
        allow(drive_service).to receive(:delete_file).and_raise(
          Google::Apis::AuthorizationError.new("Unauthorized.", status_code: 401)
        )
      end

      it "raises GoogleDrive::Errors::AuthorizationError" do
        expect { described_class.delete_file("abc123") }.to raise_error(GoogleDrive::Errors::AuthorizationError, /Unauthorized/)
      end
    end
  end
end
