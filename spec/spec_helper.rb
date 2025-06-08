# frozen_string_literal: true

ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'
require 'minitest/rg'
require 'yaml'

require_relative 'test_load_all'

def authenticate(account_data)
  credentials = {
    username: account_data['username'],
    password: account_data['password']
  }
  UCCMe::AuthenticateAccount.call(credentials)
end

def auth_header(account_data)
  authenticated_account = authenticate(account_data)
  "Bearer #{authenticated_account[:attributes][:auth_token]}"
end

def authorization(account_data)
  authenticated_account = authenticate(account_data)
  token = AuthToken.new(authenticated_account[:attributes][:auth_token])
  account_data = token.payload['attributes']
  account = UCCMe::Account.first(username: account_data['username'])
  UCCMe::AuthorizedAccount.new(account, token.scope)
end

# Helper to clean database during test runs
module DatabaseHelper
  def self.wipe_database
    UCCMe::FileShare.map(&:destroy)
    UCCMe::StoredFile.map(&:destroy)
    UCCMe::Folder.map(&:destroy)
    UCCMe::Account.map(&:destroy)
  end
end

DATA = {
  accounts: YAML.load_file('db/seeds/accounts_seeds.yml'),
  stored_files: YAML.safe_load_file('db/seeds/stored_files_seeds.yml'),
  folders: YAML.safe_load_file('db/seeds/folders_seeds.yml')
}.freeze
