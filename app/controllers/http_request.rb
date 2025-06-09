# frozen_string_literal: true

module UCCMe
  # Handles HTTP requests
  class HttpRequest
    def initialize(roda_routing)
      @routing = roda_routing
    end

    def secure?
      raise 'Secure schema not configured' unless Api.config.SECURE_SCHEME

      @routing.scheme.casecmp(Api.config.SECURE_SCHEME).zero?
    end

    def authorized_account
      return nil unless @routing.headers['AUTHORIZATION']

      scheme, auth_token = @routing.headers['AUTHORIZATION'].split
      return nil unless scheme.match?(/^Bearer$/i)

      account_payload = AuthToken.new(auth_token).payload
      account = Account.first(username: account_payload['attributes']['username'])
      token = AuthToken.new(auth_token)
      AuthorizedAccount.new(account, token.scope)
    end

    def body_data
      JSON.parse(@routing.body.read, symbolize_names: true)
    end

    def form_data
      @routing.params.transform_keys(&:to_sym)
    end
  end
end
