# frozen_string_literal: true

ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'
require 'minitest/rg'
require 'yaml'

require_relative 'test_load_all'

# Helper to clean database during test runs
module DatabaseHelper
  def self.wipe_database
    db = UCCMe::Api.DB
    # Ignore foreign key constraints when wiping tables
    db.run('PRAGMA foreign_keys = OFF')
    UCCMe::Folder.map(&:destroy)
    UCCMe::StoredFile.map(&:destroy)
    UCCMe::Account.map(&:destroy)
    db.run('PRAGMA foreign_keys = ON')
  end
end

def authenticate(account_data)
  UCCMe::AuthenticateAccount.call(
    username: account_data['username'],
    password: account_data['password']
  )
end

def auth_header(account_data)
  auth = UCCMe::AuthenticateAccount.call(
    username: account_data['username'],
    password: account_data['password']
  )

  "Bearer #{auth[:attributes][:auth_token]}"
end

def authorization(account_data)
  authenticated_account = authenticate(account_data)

  token = AuthToken.new(authenticated_account[:attributes][:auth_token])
  account_data = token.payload['attributes']
  account = UCCMe::Account.first(username: account_data['username'])
  UCCMe::AuthorizedAccount.new(account, token.scope)
end

DATA = {
  accounts: YAML.load_file('db/seeds/accounts_seeds.yml'),
  stored_files: YAML.safe_load_file('db/seeds/stored_files_seeds.yml'),
  folders: YAML.safe_load_file('db/seeds/folders_seeds.yml')
}.freeze

## SSO fixtures
GH_ACCOUNT_RESPONSE = YAML.load(
  File.read('spec/fixtures/github_token_response.yml')
)
GOOD_GH_ACCESS_TOKEN = GH_ACCOUNT_RESPONSE.keys.first
SSO_ACCOUNT = YAML.load(File.read('spec/fixtures/sso_account.yml'))
