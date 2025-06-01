# frozen_string_literal: true

require 'pry'

require_relative '../spec_helper'

describe 'Test Folder API' do
  include Rack::Test::Methods

  before do
    DatabaseHelper.wipe_database
  end

  describe 'Getting folders' do
    describe 'Getting list of folders' do
      before do
        @account_data = DATA[:accounts][0]
        @req_header = { 'CONTENT_TYPE' => 'application/json' }
        account = UCCMe::Account.create(@account_data)

        DATA[:folders].each do |folder_data|
          UCCMe::CreateFolderForOwner.call(
            owner_id: account.id,
            folder_data: {
              foldername: folder_data['foldername'] || folder_data[:foldername],
              description: folder_data['description'] || folder_data[:description]
            }
          )
        end
      end

      it 'HAPPY: should get list for authorized account' do
        auth = UCCMe::AuthenticateAccount.call(
          username: @account_data['username'],
          password: @account_data['password']
        )
        header 'AUTHORIZATION', "Bearer #{auth[:attributes][:auth_token]}"
        get 'api/v1/folders'
        _(last_response.status).must_equal 200

        result = JSON.parse(last_response.body)
        _(result['data'].count).must_equal 3
      end

      it 'BAD: should not process for unauthorized account' do
        header 'AUTHORIZATION', 'Bearer bad_token'
        get 'api/v1/folders'
        _(last_response.status).must_equal 403

        result = JSON.parse(last_response.body)
        _(result['data']).must_be_nil
      end
    end

    it 'HAPPY: should be able to get details of a single folder' do
      # Create owner first
      owner = UCCMe::Account.create(DATA[:accounts][0])

      folder_data = {
        foldername: DATA[:folders][1]['foldername'] || DATA[:folders][1][:foldername],
        description: DATA[:folders][1]['description'] || DATA[:folders][1][:description]
      }

      folder = UCCMe::CreateFolderForOwner.call(
        owner_id: owner.id,
        folder_data: folder_data
      )
      id = folder.id

      get "/api/v1/folders/#{id}"
      _(last_response.status).must_equal 200

      result = JSON.parse(last_response.body)
      _(result['attributes']['id']).must_equal id
      _(result['attributes']['foldername']).must_equal folder_data[:foldername]
      _(result['attributes']['description']).must_equal folder_data[:description]
    end

    it 'SAD: should return error if unknown folder requested' do
      get '/api/v1/folders/foobar'
      _(last_response.status).must_equal 404
    end

    it 'SECURITY: should prevent basic SQL injection targeting IDs' do
      # Create owner first
      owner = UCCMe::Account.create(DATA[:accounts][0])

      UCCMe::CreateFolderForOwner.call(
        owner_id: owner.id,
        folder_data: {
          foldername: 'Folder One',
          description: 'First folder'
        }
      )

      UCCMe::CreateFolderForOwner.call(
        owner_id: owner.id,
        folder_data: {
          foldername: 'Folder Two',
          description: 'Second folder'
        }
      )

      get 'api/v1/folders/2%20or%20id%3E0'

      # deliberately not reporting error -- don't give attacker information
      _(last_response.status).must_equal 404
      _(JSON.parse(last_response.body)['data']).must_be_nil
    end
  end

  describe 'Creating New Folders' do
    before do
      @req_header = { 'CONTENT_TYPE' => 'application/json' }
      @folder_data = {
        foldername: DATA[:folders][1]['foldername'] || DATA[:folders][1][:foldername],
        description: DATA[:folders][1]['description'] || DATA[:folders][1][:description]
      }
    end

    it 'HAPPY: should be able to create new folders' do
      # Create owner first
      owner = UCCMe::Account.create(DATA[:accounts][0])

      # Add owner_id to the request data
      @folder_data_with_owner = @folder_data.merge(owner_id: owner.id)

      post 'api/v1/folders', @folder_data_with_owner.to_json, @req_header
      _(last_response.status).must_equal 201
      _(last_response.headers['Location']).wont_be_nil
      _(last_response.headers['Location'].size).must_be :>, 0

      created = JSON.parse(last_response.body)['data']['attributes']
      folder = UCCMe::Folder.first

      _(created['id']).must_equal folder.id
      _(created['foldername']).must_equal @folder_data[:foldername]
      _(created['description']).must_equal @folder_data[:description]
    end

    it 'SECURITY: should not create folder with mass assignment' do
      # Create owner first
      owner = UCCMe::Account.create(DATA[:accounts][0])

      bad_data = @folder_data.clone
      bad_data['created_at'] = '1900-01-01'
      bad_data['owner_id'] = owner.id

      post 'api/v1/folders', bad_data.to_json, @req_header

      _(last_response.status).must_equal 400
      _(last_response.headers['Location']).must_be_nil
    end

    it 'BAD: should not create folder without required attributes' do
      # Create owner first
      owner = UCCMe::Account.create(DATA[:accounts][0])

      bad_data = {
        description: 'Missing foldername',
        owner_id: owner.id
      }

      post 'api/v1/folders', bad_data.to_json, @req_header
      _(last_response.status).must_equal 500
    end

    it 'BAD: should not accept invalid JSON' do
      post 'api/v1/folders', 'not valid json', @req_header
      _(last_response.status).must_equal 500
    end
  end
end
