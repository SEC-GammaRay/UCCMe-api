# frozen_string_literal: true

module UCCMe
  # Find account and check password
  class AuthenticateAccount
    # Error for invalid credentials
    class UnauthorizedError < StandardError
      def initialize(msg = nil)
        super(msg)
        @credentials = msg
      end

      def message
        "Invalid Credentials for: #{@credentials[:username]}"
      end
    end

    def self.call(credentials)
      account = Account.first(username: credentials[:username])
      raise unless account.password?(credentials[:password])

      AuthorizedAccount.new(account, Authscope::FULL).to_h
    rescue StandardError 
       raise UnauthorizedError
    end
  end
end