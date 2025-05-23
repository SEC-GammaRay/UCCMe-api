# frozen_string_literal: true

require 'roda'
require 'json'
require 'logger'

module UCCMe
  # main entry point
  class Api < Roda
    # plugin :environments
    plugin :halt
    plugin :multi_route
    plugin :request_headers

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

      HttpRequest.new(routing).secure? ||
        routing.halt(403, { message: 'TLS/SSL Required' }).to_json

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
