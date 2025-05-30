# frozen_string_literal: true

require 'roda'
require_relative 'app'

module UCCMe
  # Web controller for UCCMe API
  class Api < Roda
    route('auth') do |routing|
      routing.on 'register' do
        # POST /api/v1/auth/register
        routing.post do
          reg_data = JSON.parse(routing.body.read, symbolize_names: true)
          VerifyRegistration.new(Api.config, reg_data).call

          response.status = 202
          { message: 'Verification email sent' }.to_json
        rescue VerifyRegistration::InvalidRegistration => e
          routing.halt 400, { message: e.message }.to_json
        rescue VerifyRegistration::EmailProviderError => e
          Api.logger.error "Could not send email to: #{e.inspect}"
          routing.halt 500, { message: 'Error sending email' }.to_json
        rescue StandardError => e
          Api.logger.error "Could not verify registeration: #{e.inspect}"
          routing.halt 500
        end
      end

      routing.is 'authenticate' do
        # POST /api/v1/auth/authenticate
        routing.post do
          credentials = HttpRequest.new(routing).body_data
          auth_account = AuthenticateAccount.call(credentials)
          auth_account.to_json
        rescue AuthenticateAccount::UnauthorizedError
          routing.halt '403', { message: 'Invalid credentials' }.to_json
        end
      end
    end
  end
end
