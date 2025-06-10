# frozen_string_literal: true

require 'roda'
require_relative 'app'

module UCCMe
  # Web controller for UCCMe API
  class Api < Roda
    route('accounts') do |routing|
      @account_route = "#{@api_root}/accounts"
      routing.on String do |username|
        # GET api/v1/accounts/[username]
        routing.get do
          auth = AuthorizeAccount.call(
            auth: @auth_account, username: username,
            auth_scope: AuthScope::ALL
          )
          { data: auth }.to_json
        rescue AuthorizeAccount::ForbiddenError => error
          routing.halt 404, { message: error.message }.to_json
        rescue StandardError => error
          Api.logger.error "GET ACCOUNT ERROR: #{error.inspect}"
          routing.halt 500, { message: 'API Server Error' }.to_json
        end
      end

      # POST api/v1/accounts
      routing.post do
        account_data = HttpRequest.new(routing).signed_body_data
        new_account = Account.new(new_data)
        raise('Could not save account') unless new_account.save_changes

        response.status = 201
        response['Location'] = "#{@account_route}/#{new_account.id}"
        { message: 'Account created', data: new_account }.to_json
      rescue Sequel::MassAssignmentRestriction
        Api.logger.warn "MASS-ASSIGNMENT:: #{account_data.keys}"
        routing.halt 400, { message: 'Illegal Request' }.to_json
      rescue SignedRequest::VerificationError
        routing.halt 403, { message: 'Must sign request' }.to_json
      rescue StandardError => error
        Api.logger.error 'Unknown error saving account'
        routing.halt 500, { message: error.message }.to_json
      end
    end
  end
end
