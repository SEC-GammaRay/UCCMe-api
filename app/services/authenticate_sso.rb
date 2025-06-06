# frozen_string_literal: true

require 'http'

module UCCMe
    # Authenticate an SSO account based on google data
    class AuthenticateSSO 
        def call(access_token)
            google_account = get_google_account(access_token)
            sso_account = find_or_create_sso_account(google_account)

            AuthorizedAccount.new(sso_account, AuthScope: FULL).to_h 
        end 

        def get_google_account(access_token)
            google_response = HTTP.headers(
                user_agent: 'UCCMe', 
                authorization: "token #{access_token}", 
                accept: 'application/json'
            ).get(ENV.fetch('GITHUB_ACCOUNT_URL'))

            raise unless google_response == 200

            account = GoogleAccount.new(JSON.parse(google_response))
            { username: account.username, email.account.email}
        end 

        def find_or_create_sso_account(account_data)
            Account.first(email: account_data[:email])
                Account.create_github_account(account_data)
        end 
    end
end
