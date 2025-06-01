# frozen_string_literal: true

require 'mailjet'
require 'active_support/core_ext/object/blank'

module UCCMe
  # Send email verification email
  class VerifyRegistration
    # Error for invalid registration details
    class InvalidRegistration < StandardError; end

    def initialize(config, registration)
      @config = config
      @registration = registration
    end

    def call
      raise(InvalidRegistration, 'Username exists') unless username_available?
      raise(InvalidRegistration, 'Email already used') unless email_available?

      send_email_verification
    end

    def username_available?
      Account.first(username: @registration[:username]).nil?
    end

    def email_available?
      Account.first(email: @registration[:email]).nil?
    end

    def send_email_verification # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
      # Configure Mailjet with API keys
      Mailjet.configure do |config|
        config.api_key = @config.MJ_APIKEY_PUBLIC
        config.secret_key = @config.MJ_APIKEY_PRIVATE
        config.api_version = 'v3.1'
      end

      # Define the email message in Mailjet's format
      message = {
        'From' => {
          'Email' => @config.SENDER_EMAIL,
          'Name' => 'UCCMe Team'
        },
        'To' => [
          {
            'Email' => @registration[:email],
            'Name' => @registration[:username]
          }
        ],
        'Subject' => 'UCCMe Registration Verification',
        'HTMLPart' => email_body
      }

      # Send the email and handle the response
      begin
        response = Mailjet::Send.create(messages: [message])
        # Check if the email was sent successfully
        if response.attributes['Messages'][0]['Status'] != 'success'
          error_info = response.attributes['Messages'][0]['Errors']&.first || {}
          error_message = error_info['ErrorMessage'] || 'Unknown error'
          puts "EMAIL ERROR: #{error_message}"
          raise InvalidRegistration, 'Could not send verification email; please check email address'
        end
      rescue StandardError => error
        puts "EMAIL ERROR: #{error.inspect}"
        raise InvalidRegistration, 'Could not send verification email; please check email address'
      end
    end

    private

    def email_body
      verification_url = @registration[:verification_url]

      EmailHelper.render(
        body_name: 'registration_email.erb',
        variables: {
          'verification_url' => verification_url
        }
      )
    end
  end
end
