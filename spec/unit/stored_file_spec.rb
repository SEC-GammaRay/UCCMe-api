# frozen_string_literal: true

require_relative '../integration/spec_helper'

describe 'Test Stored File Handling' do
  before do
    wipe_database

    DATA[:stored_files].each do |file_data|
      print(file_data)
      UCCMe::StoredFile.create(file_data)
    end
  end

  # it 'HAPPY: should be able to get list of all stored files in a folder' do
  #   folder = UCCMe::Folder.first
  #   DATA[:files].each do |file_data|
  #     folder.add_stored_file(file_data)
  #   end

  #   get "api/v1/folders/file/#{file.id}"
  #   _(last_response.status).must_equal 200

  #   result = JSON.parse(last_response.body)
  #   _(result['data'].count).must_equal DATA[:files].count
  # end

  # it 'HAPPY: should be able to get details of a single stored file' do
  #   file_data = DATA[:files][0]
  #   folder = UCCMe::Folder.first
  #   file = folder.add_stored_file(file_data).save

  #   get "/api/v1/folders/#{folder.id}/files/#{file.id}"
  #   _(last_response.status).must_equal 200

  #   result = JSON.parse(last_response.body)
  #   _(result['data']['attributes']['id']).must_equal file.id
  #   _(result['data']['attributes']['filename']).must_equal file_data['filename']
  #   _(result['data']['attributes']['description']).must_equal file_data['description']
  #   _(result['data']['attributes']['cc_types']).must_equal file_data['cc_types']
  # end

  # it 'SAD: should return error if unknown stored file requested' do
  #   folder = UCCMe::Folder.first
  #   get "/api/v1/folders/#{folder.id}/files/foobar"
  #   _(last_response.status).must_equal 404
  # end

  # it 'HAPPY: should be able to create new stored files' do
  #   folder = UCCMe::Folder.first
  #   file_data = DATA[:files][0]

  #   req_header = { 'CONTENT_TYPE' => 'application/json' }
  #   post "api/v1/folders/#{folder.id}/files",
  #        file_data.to_json, req_header
  #   _(last_response.status).must_equal 201
  #   _(last_response.headers['Location'].size).must_be :>, 0

  #   created = JSON.parse(last_response.body)['data']['attributes']
  #   file = UCCMe::StoredFile.last

  #   _(created['id']).must_equal file.id
  #   _(created['filename']).must_equal file_data['filename']
  #   _(created['description']).must_equal file_data['description']
  #   _(created['cc_types']).must_equal file_data['cc_types']

  # it 'SECURITY: should secure sensitive attributes' do
  #   stored_file_data = DATA[:files][0]
  #   folder = UCCMe::Folder.first
  #   new_file = folder.add_stored_file(filename: stored_file_data[:filename],
  #                                     cc_types: stored_file_data[:cc_types])
  #   new_file_secure = app.DB[:stored_files].first

  #   _(new_file_secure[:filename_secure]).wont_equal new_file.filename
  #   _(new_file_secure[:cc_types_secure]).wont_equal new_file.cc_types
  # end
end
