# frozen_string_literal: true

require_relative '../spec_helper'

describe 'Test File Handling' do
  include Rack::Test::Methods

  before do
    DatabaseHelper.wipe_database

    @account_data = DATA[:accounts][0]
    @wrong_account_data = DATA[:accounts][1]

    @account = UCCMe::Account.create(@account_data)
    @account.add_owned_folder(DATA[:folders][0])
    @account.add_owned_folder(DATA[:folders][1])
    UCCMe::Account.create(@wrong_account_data)

    header 'CONTENT_TYPE', 'application/json'
  end

  describe 'Getting a single file' do
    it 'HAPPY: should be able to get details of a single file' do
      file_data = DATA[:stored_files][0]
      s3_path = get_s3_path(file_data['filename'], UCCMe::Api.config)
      file_data = file_data.merge('s3_path' => s3_path)
      folder = @account.folders.first
      file = folder.add_stored_file(file_data)

      header 'AUTHORIZATION', auth_header(@account_data)
      get "/api/v1/files/#{file.id}"
      _(last_response.status).must_equal 200

      result = JSON.parse(last_response.body)['data']
      _(result['attributes']['id']).must_equal file.id
      _(result['attributes']['filename']).must_equal file_data['filename']
    end

    it 'SAD AUTHORIZATION: should not get file details without authorization' do
      file_data = DATA[:stored_files][0]
      s3_path = get_s3_path(file_data['filename'], UCCMe::Api.config)
      file_data = file_data.merge('s3_path' => s3_path)
      folder = UCCMe::Folder.first
      file = folder.add_stored_file(file_data)

      get "/api/v1/files/#{file.id}"

      result = JSON.parse(last_response.body)

      _(last_response.status).must_equal 403
      _(result['attributes']).must_be_nil
    end

    # it 'BAD AUTHORIZATION: should not get file details with wrong authorization' do
    #   file_data = DATA[:stored_files][0]
    #   folder = @account.folders.first
    #   file = folder.add_stored_file(file_data)

    #   header 'AUTHORIZATION', auth_header(@wrong_account_data)
    #   get "/api/v1/files/#{file.id}"

    #   result = JSON.parse(last_response.body)

    #   _(last_response.status).must_equal 403
    #   _(result['attributes']).must_be_nil
    # end

    it 'SAD: should return error if unknown file requested' do
      header 'AUTHORIZATION', auth_header(@account_data)
      get '/api/v1/files/foobar'

      _(last_response.status).must_equal 404
    end
  end

  # describe 'Creating Files' do
  #   before do
  #     @folder = UCCMe::Folder.first
  #     @file_data = DATA[:stored_files][0]
  #     @req_header = { 'CONTENT_TYPE' => 'application/json' }
  #   end

  #   it 'HAPPY: should be able to create new files' do
  #     post 'api/v1/files',
  #          filter_file_data(@file_data).to_json, @req_header
  #     _(last_response.status).must_equal 201

  #     created = JSON.parse(last_response.body)
  #     _(created['message']).must_equal 'Document saved'
  #     _(created['id']).wont_be_nil

  #     file = UCCMe::StoredFile.last
  #     _(file.filename).must_equal @file_data['filename']
  #   end

  #   it 'SECURITY: should not create files with mass assignment' do
  #     bad_data = @file_data.clone
  #     bad_data['created_at'] = '1900-01-01'
  #     bad_data['id'] = 'hacked_id'

  #     post 'api/v1/files',
  #          bad_data.to_json, @req_header
  #     _(last_response.status).must_equal 400
  #     _(last_response.headers['Location']).must_be_nil
  #   end
  # end

  describe 'File Route Structures' do
    it 'should correctly build file route paths' do
      folder = UCCMe::Folder.first
      # file = folder.add_stored_file(filter_file_data(DATA[:stored_files][0]))
      file_data = DATA[:stored_files][0]
      s3_path = get_s3_path(file_data['filename'], UCCMe::Api.config)
      file_data = file_data.merge('s3_path' => s3_path)
      file = UCCMe::CreateFileForFolder.call(
        account: folder.owner,
        folder_id: folder.id,
        file_data: file_data
      )

      header 'AUTHORIZATION', auth_header(@account_data)
      get "api/v1/files/#{file.id}"
      _(last_response.status).must_equal 200
    end
  end
end
