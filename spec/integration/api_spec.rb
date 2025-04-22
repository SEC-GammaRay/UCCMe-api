# frozen_string_literal: true

# require 'minitest/autorun'
# require 'minitest/rg'
# require 'rack/test'
# require 'yaml'
require_relative 'spec_helper'

# require_relative '../app/controllers/app'
# require_relative '../app/models/property'

# def app
#   UCCMe::Api
# end

# VALID_CC_TYPES = [
#   'CC BY',
#   'CC BY-SA',
#   'CC BY-ND',
#   'CC BY-NC',
#   'CC BY-NC-SA',
#   'CC BY-NC-ND'
# ].freeze

# DATA = YAML.safe_load_file('db/seeds/document_seeds.yml')

describe 'Test UCCMe Web API' do
  # include Rack::Test::Methods

  # delete all data before each test
  before do
    Dir.glob('db/local/*.txt').each { |filename| FileUtils.rm(filename) }
  end

  # test GET request
  it 'should find the root route' do
    get '/'
    _(last_response.status).must_equal 200
  end

  # describe 'Handle files' do
  #   # HAPPT TEST: files counts
  #   it 'HAPPY: should be able to list all documents' do
  #     UCCMe::StoredFile.new(DATA[0]).save
  #     UCCMe::StoredFile.new(DATA[1]).save

  #     get 'api/v1/files'
  #     result = JSON.parse last_response.body

  #     _(result['id'].count).must_equal 2
  #   end

  #   # HAPPY TEST: fetch id
  #   it 'HAPPY: should be able to get details of a single document' do
  #     UCCMe::StoredFile.new(DATA[1]).save
  #     id = Dir.glob('db/local/*.txt').first.split(%r{[/\.]})[-2]

  #     get "api/v1/files/#{id}"
  #     result = JSON.parse last_response.body

  #     _(last_response.status).must_equal 200
  #     _(result['id']).must_equal id
  #   end

  #   # HAPPT TEST: create new doc
  #   it 'HAPPY: should be able to create new files' do
  #     req_header = { 'CONTENT_TYPE' => 'application/json' }

  #     post 'api/v1/files', DATA[1].to_json, req_header

  #     _(last_response.status).must_equal 201
  #   end

  #   it 'HAPPY: should be 1 of 6 cc code types' do
  #     DATA.each do |data|
  #       UCCMe::StoredFile.new(data).save
  #     end

  #     file_ids = Dir.glob('db/local/*.txt').map { |path| path.split(%r{[/\.]})[-2] }

  #     file_ids.each do |id|
  #       get "api/v1/files/#{id}"
  #       result = JSON.parse last_response.body
  #       _(VALID_CC_TYPES).must_include result['cc_types'].first
  #     end
  #   end

  # SAD: request file not exist
  it 'SAD: should return error if unknown document requested' do
    get 'api/v1/files/foobar'

    _(last_response.status).must_equal 404
  end
end

describe 'Creating New Folder' do
  before do
    @request_header = { 'CONTENT_TYPE' => 'application/json' }
    @folder_data = DATA[:folders][0]
  end

  it 'SECURITY: should not create project with mass assignment' do
    bad_data = @folder_data.clone
    bad_data[:id] = 9999
    post 'api/v1/folders', bad_data.to_json, @request_header

    _(last_response.status).must_equal 404
  end

  it 'SECUTIRY: should prevent basic SQL injection to get index' do
    get 'api/v1/folders/2%20or%20id%3D1'

    _(last_response.status).must_equal 404
    # _(last_response.body).must_be_nil
  end
end
