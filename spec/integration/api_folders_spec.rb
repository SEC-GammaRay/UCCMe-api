# frozen_string_literal: true

require 'pry'

require_relative '../spec_helper'

describe 'Test Folder API' do
  include Rack::Test::Methods

  before do
    DatabaseHelper.wipe_database
    @account_data = DATA[:accounts][0]
    @wrong_account_data = DATA[:accounts][1]

    @account = UCCMe::Account.create(@account_data)
    @wrong_account = UCCMe::Account.create(@wrong_account_data)

    header 'CONTENT_TYPE', 'application/json'
  end

  describe 'Getting folders' do
    describe 'Getting list of folders' do
      before do
        @account.add_owned_folder(DATA[:folders][0])
        @account.add_owned_folder(DATA[:folders][1])
        @account.add_owned_folder(DATA[:folders][2])
      end

      it 'HAPPY: should get list for authorized account' do
        header 'AUTHORIZATION', auth_header(@account_data)
        get 'api/v1/folders'
        _(last_response.status).must_equal 200

        result = JSON.parse(last_response.body)
        _(result['data'].count).must_equal 3
      end

      it 'BAD: should not process without authorization' do
        get 'api/v1/folders'
        _(last_response.status).must_equal 403

        result = JSON.parse(last_response.body)
        _(result['data']).must_be_nil
      end
    end

    it 'HAPPY: should be able to get details of a single folder' do
      folder = @account.add_owned_folder(DATA[:folders][0])

      header 'AUTHORIZATION', auth_header(@account_data)

      get "/api/v1/folders/#{folder.id}"
      _(last_response.status).must_equal 200

      result = JSON.parse(last_response.body)['data']
      _(result['attributes']['id']).must_equal folder.id
      _(result['attributes']['foldername']).must_equal folder.foldername
      _(result['attributes']['description']).must_equal folder.description
    end

    it 'SAD: should return error if unknown folder requested' do
      header 'AUTHORIZATION', auth_header(@account_data)
      get '/api/v1/folders/foobar'

      _(last_response.status).must_equal 404
    end

    it 'BAD AUTHORAZATION: should not get folder with wrong authorization' do
      folder = @account.add_owned_folder(DATA[:folders][0])

      header 'AUTHORIZATION', auth_header(@wrong_account_data)
      get "/api/v1/folders/#{folder.id}"
      _(last_response.status).must_equal 403

      result = JSON.parse(last_response.body)
      _(result['attributes']).must_be_nil
    end

    it 'SECURITY: should prevent basic SQL injection targeting IDs' do
      @account.add_owned_folder(DATA[:folders][0])
      @account.add_owned_folder(DATA[:folders][1])
      @account.add_owned_folder(DATA[:folders][2])

      header 'AUTHORIZATION', auth_header(@account_data)
      get 'api/v1/folders/2%20or%20id%3E0'

      # deliberately not reporting error -- don't give attacker information
      _(last_response.status).must_equal 404
      _(JSON.parse(last_response.body)['data']).must_be_nil
    end
  end

  describe 'Creating New Folders' do
    before do
      @folder_data = DATA[:folders][0]
    end

    it 'HAPPY: should be able to create new folders' do
      header 'AUTHORIZATION', auth_header(@account_data)
      post 'api/v1/folders', @folder_data.to_json

      _(last_response.status).must_equal 201
      _(last_response.headers['Location']).wont_be_nil
      _(last_response.headers['Location'].size).must_be :>, 0

      created = JSON.parse(last_response.body)['data']['attributes']
      folder = UCCMe::Folder.first

      _(created['id']).must_equal folder.id
      _(created['foldername']).must_equal @folder_data['foldername']
      _(created['description']).must_equal @folder_data['description']
    end

    it 'SAD: should not create new folder without authorization' do
      post 'api/v1/folders', @folder_data.to_json

      created = JSON.parse(last_response.body)['data']

      _(last_response.status).must_equal 403
      _(last_response.headers['Location']).must_be_nil
      _(created).must_be_nil
    end

    it 'SECURITY: should not create folder with mass assignment' do
      bad_data = @folder_data.clone
      bad_data['created_at'] = '1900-01-01'

      header 'AUTHORIZATION', auth_header(@account_data)
      post 'api/v1/folders', bad_data.to_json

      _(last_response.status).must_equal 400
      _(last_response.headers['Location']).must_be_nil
    end

    # it 'BAD: should not create folder without required attributes' do
    #   bad_data = {
    #     description: 'Missing foldername',
    #     owner_id: @account_data[:id]
    #   }

    #   header 'AUTHORIZATION', auth_header(@account_data)
    #   post 'api/v1/folders', bad_data.to_json

    #   _(last_response.status).must_equal 500
    # end

    # it 'BAD: should not accept invalid JSON' do
    #   header 'AUTHORIZATION', auth_header(@account_data)
    #   post 'api/v1/folders', 'not valid json'

    #   _(last_response.status).must_equal 500
    # end
  end
end
