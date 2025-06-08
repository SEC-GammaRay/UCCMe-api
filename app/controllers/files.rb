# frozen_string_literal: true

require_relative 'app'

module UCCMe
  # Web controller for UCCMe API
  class Api < Roda
    route('files') do |routing|
      routing.halt(403, { message: 'Not authorized' }.to_json) unless @auth_account

      @file_route = "#{@api_root}/files"

      # GET api/v1/files/[file_id]
      routing.on String do |file_id|
        @req_file = StoredFile.first(id: file_id)

        routing.get do
          # Get auth token from header
          # auth_header = routing.headers['AUTHORIZATION']
          # auth_token = AuthToken.new(auth_header.split[1]) if auth_header

          file = GetFileQuery.call(
            auth: @auth, 
            file: @req_file,
            account: @auth_account
          )
          { data: file }.to_json
        rescue GetFileQuery::ForbiddenError => error
          routing.halt 403, { message: error.message }.to_json
        rescue GetFileQuery::NotFoundError => error
          routing.halt 404, { message: error.message }.to_json
        rescue StandardError => error
          Api.logger.warn "File Error: #{error.inspect}"
          routing.halt 500, { message: 'API server error' }.to_json
        end

        # DELETE api/v1/files/[file_id]
        routing.delete do
          # auth_header = routing.headers['AUTHORIZATION']
          # auth_token = AuthToken.new(auth_header.split[1]) if auth_header
          auth_scope = AuthScope.new(@auth.scope)
          
          policy = FilePolicy.new(@auth_account, @req_file, auth_scope)
          
          routing.halt 403, { message: 'Not authorized to delete this file' }.to_json unless policy.can_delete?
          
          @req_file.destroy
          { message: 'File deleted successfully' }.to_json
        rescue StandardError => error
          Api.logger.error "DELETE FILE ERROR: #{error.inspect}"
          routing.halt 500, { message: 'Error deleting file' }.to_json
        end
      end
    end
  end
end
