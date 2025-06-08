# frozen_string_literal: true

require_relative 'app'

module UCCMe
  # Routes for file sharing
  class Api < Roda
    route('shares') do |routing|
      routing.halt(403, { message: 'Not authorized' }.to_json) unless @auth_account

      @shares_route = "#{@api_root}/shares"

      # POST api/v1/shares/files/[file_id]
      routing.on 'files' do
        routing.on String do |file_id|
          routing.post do
            share_data = HttpRequest.new(routing).body_data
            
            # Extract auth_scope from the token
            # auth_token = AuthToken.new(routing.headers['AUTHORIZATION'].split[1])
            auth_scope = AuthScope.new(@auth.scope)

            new_share = ShareFile.call(
              account: @auth_account,
              file_id: file_id,
              share_with_email: share_data[:share_with_email],
              permissions: share_data[:permissions] || ['view'],
              expires_at: share_data[:expires_at] ? Time.parse(share_data[:expires_at]) : nil,
              auth_scope: auth_scope
            )

            response.status = 201
            { message: 'File shared successfully', data: new_share }.to_json
          rescue ShareFile::ForbiddenError => e
            routing.halt 403, { message: e.message }.to_json
          rescue ShareFile::NotFoundError => e
            routing.halt 404, { message: e.message }.to_json
          rescue StandardError => e
            Api.logger.error "SHARE FILE ERROR: #{e.inspect}"
            routing.halt 500, { message: 'Error sharing file' }.to_json
          end

          # GET api/v1/shares/files/[file_id]
          routing.get do
            # auth_token = AuthToken.new(routing.headers['AUTHORIZATION'].split[1])
            
            shares = ManageFileShares.get_file_shares(
              file_id: file_id,
              account: @auth_account,
              auth: @auth
            )

            { data: shares }.to_json
          rescue ManageFileShares::ForbiddenError => e
            routing.halt 403, { message: e.message }.to_json
          rescue ManageFileShares::NotFoundError => e
            routing.halt 404, { message: e.message }.to_json
          rescue StandardError => e
            Api.logger.error "GET SHARES ERROR: #{e.inspect}"
            routing.halt 500, { message: 'Error retrieving shares' }.to_json
          end
        end
      end

      # DELETE api/v1/shares/[share_id]
      routing.on String do |share_id|
        routing.delete do
          # auth_token = AuthToken.new(routing.headers['AUTHORIZATION'].split[1])
          
          deleted_share = ManageFileShares.delete_share(
            share_id: share_id,
            account: @auth_account,
            auth: @auth
          )

          { message: 'Share deleted successfully', data: deleted_share }.to_json
        rescue ManageFileShares::ForbiddenError => e
          routing.halt 403, { message: e.message }.to_json
        rescue ManageFileShares::NotFoundError => e
          routing.halt 404, { message: e.message }.to_json
        rescue StandardError => e
          Api.logger.error "DELETE SHARE ERROR: #{e.inspect}"
          routing.halt 500, { message: 'Error deleting share' }.to_json
        end
      end
    end
  end
end
