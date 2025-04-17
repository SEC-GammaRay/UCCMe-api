# frozen_string_literal: true

ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'
require 'minitest/rg'
require 'sequel'

require_relative '../config/environments'

describe 'Test environment configuration' do
  it 'HAPPY: should have correct test database url' do
    db_url = UCCMe::Api::DB.url
    _(db_url).must_match(/test\.db/)
  end

  it 'should load environment variables from secrets.yml' do
    _(UCCMe::Api.config).must_respond_to :[]
  end

  it 'HAPPY: database URL should not be found in environment variables' do
    _(ENV.fetch('DATABASE_URL', nil)).must_be_nil
  end
end

describe 'Database Setup' do
  it 'HAPPY: should have sequel as ORM' do
    _(UCCMe::Api::DB).must_be_kind_of Sequel::SQLite::Database
  end

  it 'should create a database connection' do
    _(UCCMe::Api.DB).must_be_instance_of Sequel::SQLite::Database
  end

  it 'should correctly set the database URL' do
    # Check that the database path is correctly formed
    db_path = UCCMe::Api.DB.opts[:database]
    _(db_path).must_match(/test\.db$/)
  end

  it 'should not find database url' do
    _(UCCMe::Api.config.DATABASE_URL).must_be_nil
  end
end
