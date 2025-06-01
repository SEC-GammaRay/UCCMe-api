# frozen_string_literal: true

require_relative '../spec_helper'

describe 'Test Authentication Routes' do
  include Rack::Test::Methods

  before do
    @req_header = { 'CONTENT_TYPE' => 'application/json' }
    DatabaseHelper.wipe_database
  end

  describe 'Account Authentication' do
    before do
      @account_data = DATA[:accounts][0]
      @account = UCCMe::Account.create(@account_data)
    end

    it 'HAPPY: should authenticate valid credentials' do
      credentials = { username: @account_data['username'],
                      password: @account_data['password'] }
      post 'api/v1/auth/authenticate', credentials.to_json, @req_header

      auth_account = JSON.parse(last_response.body)['attributes']['account']['attributes']
      _(last_response.status).must_equal 200
      _(auth_account['username']).must_equal(@account_data['username'])
      _(auth_account['email']).must_equal(@account_data['email'])
      _(auth_account['id']).wont_be_nil
    end

    it 'BAD: should not authenticate invalid password' do
      credentials = { username: @account_data['username'],
                      password: 'wrongpassword' }

      post 'api/v1/auth/authenticate', credentials.to_json, @req_header
      result = JSON.parse(last_response.body)

      _(last_response.status).must_equal 403
      _(result['message']).wont_be_nil
      _(result['username']).must_be_nil
      _(result['email']).must_be_nil
      _(result['id']).must_be_nil
    end

    it 'BAD: should not authenticate unknown account' do
      credentials = { username: 'unknown',
                      password: 'password' }

      post 'api/v1/auth/authenticate', credentials.to_json, @req_header

      result = JSON.parse(last_response.body)

      _(last_response.status).must_equal 403
      _(result['message']).wont_be_nil
      _(result['attributes']).must_be_nil
    end
  end
end
