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
          file = GetFileQuery.call(
            auth: @auth, file: @req_file
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
      end
    end
  end
end
