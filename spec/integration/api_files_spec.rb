# frozen_string_literal: true

require_relative '../spec_helper'

def filter_folder_data(data)
  return {} if data.nil?

  # Add explicit handling for converting string/symbol keys
  {
    foldername: data['foldername'] || data[:foldername],
    description: data['description'] || data[:description]
  }
end

def filter_file_data(data)
  return {} if data.nil?

  # Add explicit handling for converting string/symbol keys
  result = {}
  result[:filename] = data['filename'] || data[:filename]
  result[:description] = data['description'] || data[:description]
  result[:content] = data['content'] || data[:content]
  result[:cc_types] = data['cc_types'] || data[:cc_types]
  result
end

describe 'Test File Handling' do
  include Rack::Test::Methods

  before do
    wipe_database
    # Create folders first since files belong to folders
    DATA[:folders].each do |folder_data|
      UCCMe::Folder.create(filter_folder_data(folder_data))
    end
  end

  it 'HAPPY: should be able to get list of all files in a folder' do
    folder = UCCMe::Folder.first
    DATA[:stored_files].each do |file_data|
      folder.add_stored_file(filter_file_data(file_data))
    end

    get "api/v1/folders/#{folder.id}/files"
    _(last_response.status).must_equal 200

    result = JSON.parse last_response.body
    _(result['data'].count).must_equal 3
  end

  it 'HAPPY: should be able to get details of a single file' do
    file_data = DATA[:stored_files][0]
    folder = UCCMe::Folder.first
    file = folder.add_stored_file(filter_file_data(file_data))

    get "/api/v1/folders/#{folder.id}/files/#{file.id}"
    _(last_response.status).must_equal 200
    result = JSON.parse last_response.body
    _(result['id']).must_equal file.id
    _(result['filename']).must_equal file_data['filename']
    _(result['description']).must_equal file_data['description']
    _(result['content']).must_equal file_data['content']
    _(result['cc_types']).must_equal file_data['cc_types']
  end

  it 'SAD: should return error if unknown file requested' do
    folder = UCCMe::Folder.first
    get "/api/v1/folders/#{folder.id}/files/foobar"
    _(last_response.status).must_equal 404
  end

  describe 'Creating Files' do
    before do
      @folder = UCCMe::Folder.first
      @file_data = DATA[:stored_files][0]
      @req_header = { 'CONTENT_TYPE' => 'application/json' }
    end

    it 'HAPPY: should be able to create new files' do
      post "api/v1/folders/#{@folder.id}/files",
           filter_file_data(@file_data).to_json, @req_header
      _(last_response.status).must_equal 201

      created = JSON.parse(last_response.body)
      _(created['message']).must_equal 'Document saved'
      _(created['id']).wont_be_nil

      file = UCCMe::StoredFile.last
      _(file.filename).must_equal @file_data['filename']
      _(file.description).must_equal @file_data['description']
      _(file.content).must_equal @file_data['content']
      _(file.cc_types).must_equal @file_data['cc_types']
    end

    it 'SECURITY: should not create files with mass assignment' do
      bad_data = @file_data.clone
      bad_data['created_at'] = '1900-01-01'
      bad_data['id'] = 'hacked_id'

      post "api/v1/folders/#{@folder.id}/files",
           bad_data.to_json, @req_header
      _(last_response.status).must_equal 400
      _(last_response.headers['Location']).must_be_nil
    end

    it 'SAD: should return error for non-existent folder' do
      post 'api/v1/folders/non_existent_folder/files',
           @file_data.to_json, @req_header

      _(last_response.status).must_equal 500 # Based on your controller's error handling
      result = JSON.parse(last_response.body)
      _(result['message']).must_equal 'Unknown server error' # NOTE: typo in your controller
    end
  end

  describe 'File Route Structures' do
    it 'should correctly build file route paths' do
      folder = UCCMe::Folder.first
      file = folder.add_stored_file(filter_file_data(DATA[:stored_files][0]))

      get "api/v1/folders/#{folder.id}/files"
      _(last_response.status).must_equal 200

      get "api/v1/folders/#{folder.id}/files/#{file.id}"
      _(last_response.status).must_equal 200
    end
  end
end
