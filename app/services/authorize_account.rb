# frozen_string_literal: true

module UCCMe
  # Service to authorize account access with scoped tokens
  class AuthorizeAccount
    class ForbiddenError < StandardError
      def message
        'You are not allowed to access this account'
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
      raise ForbiddenError unless auth_scope.can_read?('account')

      # Return account data based on scope
      if auth_scope.can_share?('account')
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