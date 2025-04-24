# frozen_string_literal: true

require 'roda'
require 'json'

require_relative '../models/stored_file'
require_relative '../models/folder'

module UCCMe
  # top-level
  class Api < Roda
    plugin :environments
    plugin :halt

    configure do
      StoredFile.locate
    end

    route do |routing|
      response['Content-Type'] = 'application/json'

      routing.root do
        { message: 'UCCMeAPI up at /api/v1/folders' }.to_json
      end

      routing.on 'api' do
        routing.on 'v1' do
          routing.on 'folders' do
            # GET api/v1/folders
            routing.get do
              output = { folders: Folder.all }
              JSON.pretty_generate(output)
            rescue StandardError
              routing.halt 404, { message: 'Folder not found' }.to_json
            end

            # POST api/v1/folders
            routing.post do
              new_data = JSON.parse(routing.body.read)
              new_folder = Folder.new(new_data)
              raise('Could not save project') unless new_proj.save_changes

              response.status = 201
              response['Location'] = "api/v1/folder/#{new_folder.id}"
              { message: 'Project saved', data: new_folder }.to_json
            rescue Sequel::MassAssignmentRestriction
              Api.logger.warn "MASS-ASSIGNMENT: #{new_data.keys}"
              routing.halt 400, { message: 'Illegal Attributes' }.to_json
            rescue StandardError => e
              Api.logger.error "UNKNOWN ERROR: #{e.message}"
              routing.halt 500, { message: 'Internal Server Error' }.to_json
            end

            routing.on 'files' do
              # GET api/v1/folders/files/:id
              routing.get String do |id|
                StoredFile.find(id).to_json
              rescue StandardError
                routing.halt 404, { message: 'File not found' }.to_json
              end

              # GET api/v1/folders/files
              routing.get do
                output = { files: StoredFile.all }
                JSON.pretty_generate(output)
              end

              # POST api/v1/folders/files
              routing.post do
                new_data = JSON.parse(routing.body.read)
                new_file = StoredFile.new(new_data)

                if new_file.save_changes
                  response.status = 201
                  { message: 'Document saved', id: new_file.id }.to_json
                else
                  routing.halt 400, { message: 'Could not save file' }.to_json
                end
              end
            end
          end
        end
      end
    end
  end
end
