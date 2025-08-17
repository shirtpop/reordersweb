require 'google/apis/drive_v3'
require 'googleauth'
require 'googleauth/stores/file_token_store'

module GoogleDrive
  class Auth
    # Set up OAuth scope
    SCOPE = 'https://www.googleapis.com/auth/drive'
    DEFAULT_USER_ID = 'default'

    class << self
      def authorization
        return credentials if credentials

        request_credentials
      end

      def request_credentials
        url = authorizer.get_authorization_url(base_url:)
        puts "Open this URL in your browser: #{url}"
        puts 'after that, call get_and_store_credentials with the code you received.'
      end

      def credentials
        authorizer.get_credentials(user_id)
      end

      def user_id
        DEFAULT_USER_ID
      end

      def base_url
        ENV['GOOGLE_OAUTH_REDIRECT_URI'] || 'http://localhost:3000'
      end

      def file_path
        Rails.root.join('config', 'google_client_secret.json')
      end

      def token_path
        Rails.root.join('config', 'google_token.yaml')
      end

      def client_id
        Google::Auth::ClientId.from_file(file_path)
      end

      def token_store
        Google::Auth::Stores::FileTokenStore.new(file: token_path)
      end

      def authorizer
        Google::Auth::UserAuthorizer.new(client_id, SCOPE, token_store)
      end
    end
  end
end