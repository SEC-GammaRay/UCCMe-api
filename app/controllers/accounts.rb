# frozen_string_literal: true

require 'roda'
require_relative 'app'

module UCCMe
  # Web controller for UCCMe API
  class Api < Roda
    route('accounts') do |routing|
      @account_route = "#{@api_root}/accounts"

      routing.on String do |username|
        routing.halt(403, UNAUTH_MSG) unless @auth_account

        # GET api/v1/accounts/[username]
        routing.get do

          auth_scope = AuthScope.new(@auth.scope)


          auth = AuthorizeAccount.call(
            auth: @auth, username: username,
            auth_scope: AuthScope::VIEW_ONLY
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
        new_data = JSON.parse(routing.body.read)
        new_account = Account.new(new_data)
        raise('Could not save account') unless new_account.save_changes

        response.status = 201
        response['Location'] = "#{@account_route}/#{new_account.id}"
        { message: 'Account created', data: new_account }.to_json
      rescue Sequel::MassAssignmentRestriction
        Api.logger.warn "MASS-ASSIGNMENT:: #{new_data.keys}"
        routing.halt 400, { message: 'Illegal Request' }.to_json
      rescue StandardError => error
        Api.logger.error 'Unknown error saving account'
        routing.halt 500, { message: error.message }.to_json
      end
    end
  end
end
