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

def auth_header(account_data)
  auth = UCCMe::AuthenticateAccount.call(
    username: account_data['username'],
    password: account_data['password']
  )

  "Bearer #{auth[:attributes][:auth_token]}"
end

def get_s3_path(filename, config)
  region = config.AWS_REGION
  bucket = config.AWS_BUCKET
  prefix = config.AWS_PREFIX
  "https://#{bucket}.s3.#{region}.amazonaws.com/#{prefix}/#{filename}"
end

DATA = {
  accounts: YAML.load_file('db/seeds/accounts_seeds.yml'),
  stored_files: YAML.safe_load_file('db/seeds/stored_files_seeds.yml'),
  folders: YAML.safe_load_file('db/seeds/folders_seeds.yml')
}.freeze
