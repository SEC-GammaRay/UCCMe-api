# frozen_string_literal: true

require_relative '../integration/spec_helper'

describe 'Test Folder Handling' do
  include Rack::Test::Methods

  before do
    wipe_database
    FileUtils.rm_rf(UCCMe::STORE_DIR) # Clean up filesystem
    DATA[:folders].each do |folder_data|
      UCCMe::Folder.create(folder_data).save_to_file
    end
  end

  # it 'HAPPY: should be able to get list of all folders' do
  #   get 'api/v1/folders'
  #   _(last_response.status).must_equal 200

  #   result = JSON.parse(last_response.body)
  #   _(result['data'].count).must_equal DATA[:folders].count
  # end

  # it 'HAPPY: should be able to get details of a single folder' do
  #   folder = UCCMe::Folder.first

  #   get "/api/v1/folders/#{folder.id}"
  #   _(last_response.status).must_equal 200

  #   result = JSON.parse(last_response.body)
  #   _(result['data']['attributes']['id']).must_equal folder.id
  #   _(result['data']['attributes']['foldername']).must_equal folder.foldername
  #   _(result['data']['attributes']['description']).must_equal folder.description
  # end

  # it 'SAD: should return error if unknown folder requested' do
  #   get '/api/v1/folders/foobar'
  #   _(last_response.status).must_equal 404
  # end

  # it 'HAPPY: should be able to create new folders' do
  #   folder_data = DATA[:folders][0]

  #   req_header = { 'CONTENT_TYPE' => 'application/json' }
  #   post 'api/v1/folders', folder_data.to_json, req_header
  #   _(last_response.status).must_equal 201
  #   _(last_response.headers['Location'].size).must_be :>, 0

  #   created = JSON.parse(last_response.body)['data']['attributes']
  #   folder = UCCMe::Folder.last

  #   _(created['id']).must_equal folder.id
  #   _(created['foldername']).must_equal folder_data['foldername']
  #   _(created['description']).must_equal folder_data['description']

  #   # Verify filesystem storage
  #   _(File.exist?("#{UCCMe::STORE_DIR}/#{folder.id}.txt")).must_equal true
  # end
end
