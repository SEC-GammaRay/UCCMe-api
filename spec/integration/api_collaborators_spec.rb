# frozen_string_literal: true

require_relative '../spec_helper'

describe 'Test Collaborator Handling' do
  include Rack::Test::Methods

  before do
    DatabaseHelper.wipe_database

    @account_data = DATA[:accounts][0]
    @another_account_data = DATA[:accounts][1]
    @wrong_account_data = DATA[:accounts][2]

    @account = UCCMe::Account.create(@account_data)
    @another_account = UCCMe::Account.create(@another_account_data)
    @wrong_account = UCCMe::Account.create(@wrong_account_data)

    @folder = @account.add_owned_folder(DATA[:folders][0])

    header 'CONTENT_TYPE', 'application/json'
  end

  describe 'Adding collaborators to a folder' do
    it 'HAPPY: should add a valid collaborator' do
      req_data = { email: @another_account.email }

      header 'AUTHORIZATION', auth_header(@account_data)
      put "api/v1/folders/#{@folder.id}/collaborators", req_data.to_json

      added = JSON.parse(last_response.body)['data']['attributes']

      _(last_response.status).must_equal 200
      _(added['username']).must_equal @another_account.username
    end

    it 'SAD AUTHORIZATION: should not add collaborator without authorization' do
      req_data = { email: @another_account.email }
      put "api/v1/folders/#{@folder.id}/collaborators", req_data.to_json
      added = JSON.parse(last_response.body)['data']

      _(last_response.status).must_equal 403
      _(added).must_be_nil
    end

    it 'BAD AUTHORIZATION: should not add an invalid collaborator' do
      req_data = { email: @account.email }

      header 'AUTHORIZATION', auth_header(@account_data)
      put "api/v1/folders/#{@folder.id}/collaborators", req_data.to_json
      added = JSON.parse(last_response.body)['data']

      _(last_response.status).must_equal 403
      _(added).must_be_nil
    end
  end

  describe 'Removing collaborators from a folder' do
    it 'HAPPY: should remove with proper authorization' do
      @folder.add_collaborator(@another_account)
      req_data = { email: @another_account.email }

      header 'AUTHORIZATION', auth_header(@account_data)
      delete "api/v1/folders/#{@folder.id}/collaborators", req_data.to_json

      _(last_response.status).must_equal 200
    end

    it 'SAD: AUTHORIZATION: should not remove without authorization' do
      @folder.add_collaborator(@another_account)
      req_data = { email: @another_account.email }

      delete "api/v1/folders/#{@folder.id}/collaborators", req_data.to_json

      _(last_response.status).must_equal 403
    end

    it 'BAD AUTHORIZATION: should not remove invalid collaborator' do
      req_data = { email: @another_account.email }

      header 'AUTHORIZATION', auth_header(@account_data)
      delete "api/v1/folders/#{@folder.id}/collaborators", req_data.to_json

      _(last_response.status).must_equal 403
    end
  end
end
