# frozen_string_literal: true

require 'http'

module UCCMe
  # Authenticate an SSO account based on google data
  class AuthenticateSSO 

    def initialize
    end

    def call(access_token)
      google_account = get_google_account(access_token)
      sso_account = find_or_create_sso_account(google_account)
      AuthorizedAccount.new(sso_account, AuthScope: 'FULL').to_h 
    end 

    def get_google_account(access_token)
      google_response = HTTP.headers(
        user_agent: 'UCCMe', 
        authorization: "Bearer #{access_token}",
        accept: 'application/json'
      ).get(ENV.fetch('GOOGLE_ACCOUNT_URL'))

      unless google_response.status == 200
        Api.logger.error "Google API error: #{google_response.status} - #{google_response.body}"
        raise "Failed to fetch Google account: #{google_response.status} - #{google_response.body}"
      end

      account = GoogleAccount.new(JSON.parse(google_response.body))
      { username: account.username, email: account.email }
    rescue StandardError => e
        Api.logger.error "get_google_account error: #{e.class} - #{e.message}}"
        raise
    end 

    def find_or_create_sso_account(account_data)
      Account.first(email: account_data[:email]) || Account.create_sso_account(account_data)
    end 
  end
end