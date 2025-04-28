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

describe 'Test Folder API' do
  include Rack::Test::Methods

  before do
    wipe_database
  end

  describe 'Getting folders' do
    it 'HAPPY: should be able to get list of all folders' do
      UCCMe::Folder.create(filter_folder_data(DATA[:folders][0]))
      UCCMe::Folder.create(filter_folder_data(DATA[:folders][1]))
      UCCMe::Folder.create(filter_folder_data(DATA[:folders][2]))

      get 'api/v1/folders'
      _(last_response.status).must_equal 200

      result = JSON.parse(last_response.body)
      _(result['data'].count).must_equal 3
    end

    it 'HAPPY: should be able to get details of a single folder' do
      existing_folder = (filter_folder_data(DATA[:folders][1]))
      folder = UCCMe::Folder.create(existing_folder)
      id = folder.id

      get "/api/v1/folders/#{id}"
      _(last_response.status).must_equal 200

      result = JSON.parse(last_response.body)
      _(result['data']['attributes']['id']).must_equal id
      _(result['data']['attributes']['foldername']).must_equal existing_folder[:foldername]
      _(result['data']['attributes']['description']).must_equal existing_folder[:description]
    end

    it 'SAD: should return error if unknown folder requested' do
      get '/api/v1/folders/foobar'
      _(last_response.status).must_equal 404
    end

    it 'SECURITY: should prevent basic SQL injection targeting IDs' do
      UCCMe::Folder.create(foldername: 'Folder One', description: 'First folder')
      UCCMe::Folder.create(foldername: 'Folder Two', description: 'Second folder')
      
      get 'api/v1/folders/2%20or%20id%3E0'
      
      # deliberately not reporting error -- don't give attacker information
      _(last_response.status).must_equal 404
      _(JSON.parse(last_response.body)['data']).must_be_nil
    end
  end

  describe 'Creating New Folders' do
    before do
      @req_header = { 'CONTENT_TYPE' => 'application/json' }
      @folder_data = filter_folder_data(DATA[:folders][1])
    end

    it 'HAPPY: should be able to create new folders' do
      post 'api/v1/folders', @folder_data.to_json, @req_header
      _(last_response.status).must_equal 201
      _(last_response.headers['Location']).wont_be_nil
      _(last_response.headers['Location'].size).must_be :>, 0

      created = JSON.parse(last_response.body)['data']
      folder = UCCMe::Folder.first

      _(created['id']).must_equal folder.id
      _(created['foldername']).must_equal @folder_data[:foldername]
      _(created['description']).must_equal @folder_data[:description]
    end

    it 'SECURITY: should not create folder with mass assignment' do
      bad_data = @folder_data.clone
      bad_data['created_at'] = '1900-01-01'
      
      post 'api/v1/folders', bad_data.to_json, @req_header

      _(last_response.status).must_equal 400
      _(last_response.headers['Location']).must_be_nil
    end

    it 'BAD: should not create folder without required attributes' do
      bad_data = {
        description: 'Missing foldername'
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