# frozen_string_literal: true

require 'roda'
require_relative './app'

module UCCMe 
    class Api < Roda
        # rubocop:disable Metrics/BlockLength
        route('folders') do |routing|
            @folder_route = "#{@api_root}/folders"
  
            routing.on String do |folder_id|
              routing.on 'files' do
                @file_route = "#{@folder_route}/#{folder_id}/files"
                # GET api/v1/folders/:folder_id/files/:file_id
                routing.get String do |file_id|
                  file = StoredFile.where(folder_id: folder_id, id: file_id).first
                  file ? file.to_json : raise('File not found')
                rescue StandardError => e
                  routing.halt 404, { message: e.message }.to_json
                end
  
                # GET api/v1/folders/:folder_id/files
                routing.get do
                  output = { data: Folder.first(id: folder_id).stored_files }
                  JSON.pretty_generate(output)
                rescue StandardError
                  routing.halt 404, { message: 'File not found' }.to_json
                end
  
                # POST api/v1/folders/:folder_id/files
                routing.post do
                  new_data = JSON.parse(routing.body.read)
                  folder = Folder.first(id: folder_id)
  
                  unless folder
                    Api.logger.warn "Folder not found: #{folder_id}"
                    routing.halt 404, { message: 'Folder not found' }.to_json
                  end
  
                  new_file = folder.add_stored_file(new_data)
                  raise 'Could not save document' unless new_file
  
                  # new_file = UCCMe::CreateFileForFolder.call(
                  #   folder_id: folder_id,
                  #   file_data: new_data
                  # )
  
                  response.status = 201
                  { message: 'Document saved', id: new_file.id }.to_json
                # rescue UCCMe::CreateFileForFolder::FolderNotFoundError => e
                #   routing.halt 404, { message: e.message }.to_json
                rescue Sequel::MassAssignmentRestriction
                  Api.logger.warn "MASS-ASSIGNMENT: #{new_data.keys}"
                  routing.halt 400, { message: 'Illegal Attributes' }.to_json
                rescue StandardError => e
                  Api.logger.error "UNKNOWN ERROR: #{e.message}"
                  routing.halt 500, { message: 'Unknown server error' }.to_json
                end
              end
  
              # GET api/v1/folders/:folder_id
              routing.get do
                folder = Folder.first(id: folder_id)
                folder ? folder.to_json : raise('Folder not found')
              rescue StandardError => e
                routing.halt 404, { message: e.message }.to_json
              end
            end
  
            # GET api/v1/folders
            routing.get do
              output = { data: Folder.all }
              JSON.pretty_generate(output)
            rescue StandardError
              routing.halt 404, { message: 'Could not find folders' }.to_json
            end
  
            # POST api/v1/folders
            routing.post do
              new_data = JSON.parse(routing.body.read)
              new_folder = Folder.new(new_data)
              raise('Could not save project') unless new_folder.save_changes
  
              # new_folder = UCCMe::CreateFolderForOwner.call(new_data)
              # owner_id = new_data.delete('owner_id')
  
              # new_folder = UCCMe::CreateFolderForOwner.call(
              #   owner_id: owner_id,
              #   folder_data: new_data
              # )
  
              response.status = 201
              response['Location'] = "#{@folder_route}/#{new_folder.id}"
              { message: 'Folder created', data: new_folder }.to_json
            rescue Sequel::MassAssignmentRestriction
              Api.logger.warn "MASS-ASSIGNMENT: #{new_data.keys}"
              routing.halt 400, { message: 'Illegal Attributes' }.to_json
            rescue StandardError => e
              Api.logger.error "UNKNOWN ERROR: #{e.message}"
              routing.halt 500, { message: 'Unknown server error' }.to_json
            end
        end
      # rubocop:disable Metrics/BlockLength
    end
end
