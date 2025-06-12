# frozen_string_literal: true

require_relative '../spec_helper'
require 'webmock/minitest'

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
      # we did not implement SignedRequest
      post 'api/v1/auth/authenticate', credentials.to_json, @req_header

      auth_account = JSON.parse(last_response.body)['data']
      account = auth_account['attributes']['account']['attributes']
      _(last_response.status).must_equal 200
      _(account['username']).must_equal(@account_data['username'])
      _(account['email']).must_equal(@account_data['email'])
    end

    it 'BAD: should not authenticate invalid password' do
      bad_credentials = { username: @account_data['username'],
                          password: 'wrongpassword' }

      post 'api/v1/auth/authenticate', SignedRequest.sign(bad_credentials).to_json, @req_header
      result = JSON.parse(last_response.body)

      _(last_response.status).must_equal 403
      _(result['message']).wont_be_nil
      _(result['attributes']).must_be_nil
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

  describe 'SSO Authorization' do
    before do
      WebMock.enable!
      WebMock.stub_request(:get, app.config.GITHUB_ACCOUNT_URL)
             .to_return(body: GH_ACCOUNT_RESPONSE[GOOD_GH_ACCESS_TOKEN],
                        status: 200,
                        headers: { 'content-type' => 'application/json' })
    end

    after do
      WebMock.disable!
    end

    it 'HAPPY AUTH SSO: should authenticate+authorize new valid SSO account' do
      gh_access_token = { access_token: GOOD_GH_ACCESS_TOKEN }
      signed_payload = SignedRequest.sign(gh_access_token)
      post 'api/v1/auth/sso', signed_payload.to_json, @req_header
      # DEBUG: puts "Response status: #{last_response.status}, body: #{last_response.body}"
      # if last_response.status != 200
      #   puts "Error: Expected status 200, got #{last_response.status}"
      #   return
      # end

      auth_account = JSON.parse(last_response.body)['data']
      account = auth_account['attributes']['account']['attributes']
      _(account['username']).must_equal(SSO_ACCOUNT['sso_username'])
      _(account['email']).must_equal(SSO_ACCOUNT['email'])
    end

    it 'HAPPY AUTH SSO: should authorize existing SSO account' do
      UCCMe::Account.create(
        username: SSO_ACCOUNT['sso_username'],
        email: SSO_ACCOUNT['email']
      )

      gh_access_token = { access_token: GOOD_GH_ACCESS_TOKEN }
      post 'api/v1/auth/sso', SignedRequest.sign(gh_access_token).to_json, @req_header

      auth_account = JSON.parse(last_response.body)['data']
      account = auth_account['attributes']['account']['attributes']

      _(last_response.status).must_equal 200
      _(account['username']).must_equal(SSO_ACCOUNT['sso_username'])
      _(account['email']).must_equal(SSO_ACCOUNT['email'])
    end
  end
end
