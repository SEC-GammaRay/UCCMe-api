# frozen_string_literal: true

require 'roda'
require 'json'
require 'logger'

require_relative '../models/stored_file'
require_relative '../models/folder'
require_relative '../services/create_file_for_folder'
require_relative '../services/create_folder_for_owner'

module UCCMe
  # top-level
  class Api < Roda
    plugin :environments
    plugin :halt

    # Add a class variable for the logger
    class << self
      attr_accessor :logger
    end

    # Initialize the logger
    configure do
      StoredFile.locate
      self.logger = Logger.new($stderr)
    end

    route do |routing|
      response['Content-Type'] = 'application/json'

      routing.root do
        { message: 'UCCMeAPI up at /api/v1/folders' }.to_json
      end

      @api_root = 'api/v1'
      routing.on @api_root do
        routing.on 'auth' do
          routing.on 'authenticate' do
            # POST /api/v1/auth/authenticate
            routing.post do
              credentials = HttpRequest.new(routing).body_data
              auth_account = AuthenticateAccount.call(credentials)
              auth_account.to_json
            rescue UnauthorizedError => e
              puts [e.class, e.message].join ':'
              routing.helt '403', { message: 'Invalid credentials' }.to_json
            end
          end
        end

        routing.on 'accounts' do
          @account_route = "#{@api_root}/accounts"

          routing.on String do |username|
            # GET api/v1/accounts/[username]
            routing.get do
              account = Account.first(username:)
              account ? account.to_json : raise('Account not found')
            rescue StandardError
              routing.halt 404, { message: error.message }.to_json
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
          rescue StandardError => e
            Api.logger.error 'Unknown error saving account'
            routing.halt 500, { message: e.message }.to_json
          end
        end

        routing.on 'folders' do
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
      end
    end
  end
end
