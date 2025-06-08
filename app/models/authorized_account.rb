# frozen_string_literal: true

require 'json'

module UCCMe
  # An authorized account includes auth_token and scope
  class AuthorizedAccount
    attr_reader :account, :scope

    def initialize(account, auth_scope)
      @account = account
      @scope = AuthScope.new(auth_scope)
    end

    def token
      @token ||= AuthToken.create(
        { attributes: { username: account.username } },
        AuthToken::ONE_WEEK,
        scope
      )
    end

    def to_h
      if scope.can_copy?('account')
        # Full access - return complete account info
        {
          type: 'authorized_account',
          attributes: {
            account: account,
            auth_token: token
          }
        }
      else
        # Limited access - return only basic info
        {
          type: 'authorized_account',
          attributes: {
            account: {
              type: 'account',
              attributes: {
                username: account.username,
                id: account.id
              }
            },
            auth_token: token
          }
        }
      end
    end

    def to_json(options = {})
      JSON.generate(to_h, options)
    end
  end
end