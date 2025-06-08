# frozen_string_literal: true

require 'roda'
require 'json'
require 'logger'
require_relative 'http_request'

module UCCMe
  # main entry point
  class Api < Roda
    plugin :halt
    plugin :all_verbs
    plugin :multi_route
    plugin :request_headers

    # Add a class variable for the logger
    class << self
      attr_accessor :logger
    end

    # Unauthorized message constant
    UNAUTH_MSG = { message: 'Unauthorized Request' }.to_json

    # Initialize the logger
    configure do
      StoredFile.locate
      self.logger = Logger.new($stderr)
    end

    route do |routing|
      response['Content-Type'] = 'application/json'
      request = HttpRequest.new(routing)

      request.secure? ||
        routing.halt(403, { message: 'TLS/SSL Required' }.to_json)

      begin
        @auth_account = request.authenticated_account
        @auth = request.auth_token
      rescue AuthToken::InvalidTokenError
        routing.halt 403, { message: 'Invalid auth token' }.to_json
      rescue AuthToken::ExpiredTokenError
        routing.halt 403, { message: 'Expired auth token' }.to_json
      end

      routing.root do
        { message: 'UCCMeAPI up at /api/v1/' }.to_json
      end

      routing.on 'api' do
        routing.on 'v1' do
          @api_root = 'api/v1'
          routing.multi_route
        end
      end
    end
  end
end
