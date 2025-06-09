# frozen_string_literal: true

module UCCMe
  # Authorize an account
  class AuthorizeAccount
    # Error if requesting to see forbidden account
    class ForbiddenError < StandardError
      def message
        'You are not allowed to access that account'
      end
    end

    def self.call(auth:, username:, auth_scope:)
      # Get the requesting account from auth token
      requesting_account_username = auth.payload['attributes']['username']
      requesting_account = Account.first(username: requesting_account_username)

      # Find the target account
      target_account = Account.first(username: username)
      raise ForbiddenError unless target_account

      # Check if requesting account can view target account
      policy = AccountPolicy.new(requesting_account, target_account)
      raise ForbiddenError unless policy.can_view?

      # Check auth scope permissions
      raise ForbiddenError unless auth_scope.can_view?('account')

      # Return account data based on scope
      if auth_scope.can_copy?('account')
        # Full access - return complete account info
        target_account
      else
        # Limited access - return only basic info
        {
          type: 'account',
          attributes: {
            username: target_account.username,
            id: target_account.id
          }
        }
      end
    end
  end
end
