# frozen_string_literal: true

require_relative '../spec_helper'

describe 'Test Folder Handling' do
  include Rack::Test::Methods

  before do
    wipe_database
    FileUtils.rm_rf(UCCMe::STORE_DIR)
    # puts Sequel::Model.db.schema(:folders).inspect
    # puts DATA[:folders].inspect
    DATA[:folders].each do |folder_data|
      # unpack folder_data from hash to key value pairs
      UCCMe::Folder.create(
        foldername: folder_data[:foldername],
        description: folder_data[:description]
      )
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

  # it 'SECUTIRY: should secure sensitive attributes' do

  # end
end
