# frozen_string_literal: true

require_relative 'app'

module UCCMe
  # Web controller for UCCMe API
  class Api < Roda
    # rubocop:disable Metrics/BlockLength
    route('folders') do |routing|
      unauthorized_message = { message: 'Unauthorized Request' }.to_json
      routing.halt(403, unauthorized_message) unless @auth_account

      @folder_route = "#{@api_root}/folders"
      routing.on String do |folder_id|
        # GET api/v1/folders/[ID]
        routing.get do
          folder = GetFolderQuery.call(
            account: @auth_account,
            folder_id: folder_id
          )

          { data: folder }.to_json
        rescue GetFolderQuery::ForbiddenError => error
          routing.halt 403, { message: error.message }.to_json
        rescue GetFolderQuery::NotFoundError => error
          routing.halt 404, { message: error.message }.to_json
        rescue StandardError => error
          puts "FIND FOLDER ERROR: #{error.inspect}"
          routing.halt 500, { message: 'API server error' }.to_json
        end

        routing.on('documents') do
          # POST api/v1/folders/[folder_id]/documents
          routing.post do
            new_document = CreateFileForFolder.call(
              account: @auth_account,
              folder_id: folder_id,
              document_data: HttpRequest.new(routing).body_data
            )

            response.status = 201
            response['Location'] = "#{@doc_route}/#{new_document.id}"
            { message: 'Document saved', data: new_document }.to_json
          rescue CreateFileForFolder::ForbiddenError => error
            routing.halt 403, { message: error.message }.to_json
          rescue CreateFileForFolder::IllegalRequestError => error
            routing.halt 400, { message: error.message }.to_json
          rescue StandardError => error
            Api.logger.warn "DOCUMENT SAVING ERROR: #{error.message}"
            routing.halt 500, { message: 'Error creating document' }.to_json
          end
        end

        routing.on('collaborators') do
          # PUT api/v1/folders/[folder_id]/collaborators
          routing.put do
            req_data = JSON.parse(routing.body.read)

            collaborator = AddCollaborator.call(
              account: @auth_account,
              folder_id: folder_id,
              collab_email: req_data['email']
            )

            { data: collaborator }.to_json
          rescue AddCollaborator::ForbiddenError => error
            routing.halt 403, { message: error.message }.to_json
          rescue StandardError
            routing.halt 500, { message: 'API server error' }.to_json
          end

          # DELETE api/v1/folders/[folder_id]/collaborators
          routing.delete do
            req_data = JSON.parse(routing.body.read)
            collaborator = RemoveCollaborator.call(
              req_username: @auth_account.username,
              collab_email: req_data['email'],
              folder_id: folder_id
            )

            { message: "#{collaborator.username} removed from folder",
              data: collaborator }.to_json
          rescue RemoveCollaborator::ForbiddenError => error
            routing.halt 403, { message: error.message }.to_json
          rescue StandardError
            routing.halt 500, { message: 'API server error' }.to_json
          end
        end
      end

      routing.is do
        # GET api/v1/folders
        routing.get do
          folders = FolderPolicy::AccountScope.new(@auth_account).viewable

          JSON.pretty_generate(data: folders)
        rescue StandardError
          routing.halt 403, { message: 'Could not find any folders' }.to_json
        end

        # POST api/v1/folders
        routing.post do
          new_data = HttpRequest.new(routing).body_data
          new_folder = @auth_account.add_owned_folder(new_data)

          response.status = 201
          response['Location'] = "#{@folder_route}/#{new_folder.id}"
          { message: 'Folder saved', data: new_folder }.to_json
        rescue Sequel::MassAssignmentRestriction
          Api.logger.warn "MASS-ASSIGNMENT: #{new_data.keys}"
          routing.halt 400, { message: 'Illegal Attributes' }.to_json
        end
      end
    end
    # rubocop:disable Metrics/BlockLength
  end
end
