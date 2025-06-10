# frozen_string_literal: 

require_relative '../spec_helper'

describe 'Test Account Handling' do
  include Rack::Test::Methods

  before do
    @req_header = { 'CONTENT_TYPE' => 'application/json' }
    DatabaseHelper.wipe_database
  end

  describe 'Account Information' do
    # it 'HAPPY: should be able to get details of a single owner' do
    #   account_data = DATA[:accounts][1]
    #   account = UCCMe::Account.create(account_data)

    #   header 'AUTHORIZATION', auth_header(account_data)
    #   get "/api/v1/accounts/#{account.username}"
    #   _(last_response.status).must_equal 200

    #   result = JSON.parse(last_response.body)['data']['attributes']
    #   account_data = result['account']['attributes']
    #   _(account_data['username']).must_equal account.username
    #   _(account_data['salt']).must_be_nil
    #   _(account_data['password']).must_be_nil
    #   _(account_data['password_hash']).must_be_nil
    #   _(result['auth_token']).wont_be_nil
    # end
  end

  describe 'Account Creation' do
    before do
      @owner_data = DATA[:accounts][1]
    end

    it 'HAPPY: should be able to create new accounts' do
      post 'api/v1/accounts', @owner_data.to_json, @req_header
      _(last_response.status).must_equal 201
      _(last_response.headers['Location'].size).must_be :>, 0

      created = JSON.parse(last_response.body)['data']['attributes']
      account = UCCMe::Account.first

      _(created['id']).must_equal account.id
      _(created['username']).must_equal @owner_data['username']
      _(created['email']).must_equal @owner_data['email']
      _(account.password?(@owner_data['password'])).must_equal true
      _(account.password?('not_really_the_password')).must_equal false
    end

    it 'BAD: should not create account with illegal attributes' do
      bad_data = @owner_data.clone
      bad_data['created_at'] = '1900-01-01'
      post 'api/v1/accounts', bad_data.to_json, @req_header

      _(last_response.status).must_equal 400
      _(last_response.headers['Location']).must_be_nil
    end
  end
end
