# frozen_string_literal: true

require 'roda'
require_relative 'app'
require 'irb'

module UCCMe
  # Web controller for UCCMe API
  class Api < Roda
    route('auth') do |routing|
      # All requests in this route require signed requests
      begin
        binding.irb
        @request_data = HttpRequest.new(routing).signed_body_data
      rescue SignedRequest::VerificationError
        routing.halt '403', { message: 'Must sign request' }.to_json
      end
      

      routing.on 'register' do
        # POST /api/v1/auth/register
        routing.post do
          VerifyRegistration.new(@request_data).call

          response.status = 202
          { message: 'Verification email sent' }.to_json
        rescue VerifyRegistration::InvalidRegistration => error
          routing.halt 400, { message: error.message }.to_json
        rescue VerifyRegistration::EmailProviderError => error
          Api.logger.error "Could not send email to: #{error.inspect}"
          routing.halt 500, { message: 'Error sending email' }.to_json
        rescue StandardError => error
          Api.logger.error "Could not verify registeration: #{error.inspect}"
          routing.halt 500
        end
      end

      routing.is 'authenticate' do
        # POST /api/v1/auth/authenticate
        routing.post do
          auth_account = AuthenticateAccount.call(@request_data)
          { data: auth_account }.to_json
        rescue AuthenticateAccount::UnauthorizedError
          routing.halt '403', { message: 'Invalid credentials' }.to_json
        end
      end

      # POST /api/v1/auth/sso
      routing.post 'sso' do
        auth_account = AuthenticateSso.new.call(@request_data[:access_token])
        { data: auth_account }.to_json
      rescue StandardError => error
        Api.logger.warn "FAILED to validate Github account: #{error.inspect}" \
                        "\n#{error.backtrace}"

        routing.halt 400
      end
    end
  end
end
