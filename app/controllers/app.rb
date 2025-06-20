# frozen_string_literal: true

require 'roda'
require 'json'
require 'logger'
require_relative 'http_request'

module UCCMe
  # main entry point
  class Api < Roda
    # plugin :environments
    plugin :halt
    plugin :all_verbs
    plugin :multi_route
    plugin :request_headers

    UNAUTH_MSG = { message: 'Unauthorized Request' }.to_json

    # Add a class variable for the logger
    class << self
      attr_accessor :logger
    end

    # Initialize the logger
    configure do
      StoredFile.locate
      self.logger = Logger.new($stderr)
    end

    route do |routing|
      response['Content-Type'] = 'application/json'
      request = HttpRequest.new(routing)

      request.secure? ||
        routing.halt(403, { message: 'TLS/SSL Required' }).to_json

      begin
        @auth = request.authorized_account
        @auth_account = @auth.account if @auth
      rescue AuthToken::InvalidTokenError
        routing.halt 403, { message: 'Invalid auth token' }.to_json
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
