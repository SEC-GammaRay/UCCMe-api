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

    it 'BAD AUTHORIZATION: should not get file details with wrong authorization' do
      file_data = DATA[:stored_files][0]
      folder = @account.folders.first
      s3_path = get_s3_path(file_data['filename'], UCCMe::Api.config)
      file_data = file_data.merge('s3_path' => s3_path)
      file = folder.add_stored_file(file_data)

      header 'AUTHORIZATION', auth_header(@wrong_account_data)
      get "/api/v1/files/#{file.id}"

      result = JSON.parse(last_response.body)

      _(last_response.status).must_equal 403
      _(result['attributes']).must_be_nil
    end

    it 'SAD: should return error if unknown file requested' do
      header 'AUTHORIZATION', auth_header(@account_data)
      get '/api/v1/files/foobar'

      _(last_response.status).must_equal 404
    end
  end

  describe 'Creating Files' do
    before do
      @folder = UCCMe::Folder.first
      @file_data = DATA[:stored_files][0]
    end

    it 'HAPPY: should be able to create new files' do
      filename = @file_data['filename']
      local_path = File.join('uploads', filename)
      mime_type = get_mime_type(filename)

      # get uploaded tempfile
      tempfile = Rack::Test::UploadedFile.new(local_path, mime_type)

      header 'AUTHORIZATION', auth_header(@account_data)
      post "api/v1/folders/#{@folder.id}/files", {
        filename: filename,
        description: @file_data['description'],
        cc_types: @file_data['cc_types'],
        file: tempfile
      }
      _(last_response.status).must_equal 201
      _(last_response.headers['Location'].size).must_be :>, 0

      created = JSON.parse(last_response.body)['data']['attributes']
      stored_file = UCCMe::StoredFile.first

      _(created['id']).must_equal stored_file.id
      _(created['filename']).must_equal @file_data['filename']
      _(created['description']).must_equal @file_data['description']
    end

    it 'BAD AUTHORIZATION: should not create with incorrect authorization' do
      filename = @file_data['filename']
      local_path = File.join('uploads', filename)
      mime_type = get_mime_type(filename)

      # get uploaded tempfile
      tempfile = Rack::Test::UploadedFile.new(local_path, mime_type)

      header 'AUTHORIZATION', auth_header(@wrong_account_data)
      post "api/v1/folders/#{@folder.id}/files", {
        filename: filename,
        description: @file_data['description'],
        file: tempfile
      }

      data = JSON.parse(last_response.body)['data']

      _(last_response.status).must_equal 403
      _(last_response.headers['Location']).must_be_nil
      _(data).must_be_nil
    end

    it 'SAD AUTHORIZATION: should not create without any authorization' do
      filename = @file_data['filename']
      local_path = File.join('uploads', filename)
      mime_type = get_mime_type(filename)

      # get uploaded tempfile
      tempfile = Rack::Test::UploadedFile.new(local_path, mime_type)

      post "api/v1/folders/#{@folder.id}/files", {
        filename: filename,
        description: @file_data['description'],
        file: tempfile
      }

      data = JSON.parse(last_response.body)['data']

      _(last_response.status).must_equal 403
      _(last_response.headers['Location']).must_be_nil
      _(data).must_be_nil
    end
  end
end
