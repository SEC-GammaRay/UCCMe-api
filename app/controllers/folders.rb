# frozen_string_literal: true

require_relative 'app'

module UCCMe
  # Web controller for UCCMe API
  class Api < Roda
    route('folders') do |routing|
      unauthorized_message = { message: 'Unauthorized Request' }.to_json
      routing.halt(403, unauthorized_message) unless @auth_account

      @folder_route = "#{@api_root}/folders"
      routing.on String do |folder_id|
        # GET api/v1/folders/[ID]
        routing.get do
          folder = GetFolderQuery.call(
            auth: @auth,
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

        @file_route = "#{@api_root}/files"
        routing.on('files') do
          # POST api/v1/folders/[folder_id]/files
          routing.post do
            file_info = HttpRequest.new(routing).form_data
            file_info[:file] = file_info[:file][:tempfile]
            s3_url = FileStorageHelper.upload(file: file_info[:file], filename: file_info[:filename])
            file_info.transform_keys!(&:to_s)
            file_data = file_info.except('file').merge('s3_path' => s3_url)
            new_file = CreateFileForFolder.call(
              auth: @auth,
              folder_id: folder_id,
              file_data: file_data
            )

            response.status = 201
            response['Location'] = "#{@file_route}/#{new_file.id}"
            { message: 'File saved', data: new_file }.to_json
          rescue CreateFileForFolder::ForbiddenError => error
            routing.halt 403, { message: error.message }.to_json
          rescue CreateFileForFolder::IllegalRequestError => error
            routing.halt 400, { message: error.message }.to_json
          rescue StandardError => error
            Api.logger.warn "FILE SAVING ERROR: #{error.message}"
            routing.halt 500, { message: 'Error creating file' }.to_json
          end
        end

        routing.on('collaborators') do
          # PUT api/v1/folders/[folder_id]/collaborators
          routing.put do
            req_data = JSON.parse(routing.body.read)

            collaborator = AddCollaborator.call(
              auth: @auth,
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
              auth: @auth,
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

        routing.on('leave') do
          # DELETE api/v1/folders/[folder_id]/leave
          routing.delete do
            left_folder = LeaveFolder.call(
              auth: @auth,
              folder_id: folder_id
            )

            { message: "#{left_folder.id} removed from folder",
              data: left_folder }.to_json
          rescue LeaveFolder::ForbiddenError => error
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
          new_folder = CreateFolderForOwner.call(
            auth: @auth, folder_data: new_data
          )

          response.status = 201
          response['Location'] = "#{@folder_route}/#{new_folder.id}"
          { message: 'Folder saved', data: new_folder }.to_json
        rescue Sequel::MassAssignmentRestriction
          Api.logger.warn "MASS-ASSIGNMENT: #{new_data.keys}"
          routing.halt 400, { message: 'Illegal Attributes' }.to_json
        end
      end
    end
  end
end
