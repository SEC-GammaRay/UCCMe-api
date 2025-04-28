# frozen_string_literal: true

ENV['RACK_ENV'] = 'test'
require 'minitest/autorun'
require 'minitest/rg'
require 'yaml'
require_relative 'test_load_all'

def wipe_database
  app.DB[:stored_files].delete
  app.DB[:folders].delete
end

DATA = {
  stored_files: YAML.safe_load_file('./db/seeds/stored_files_seeds.yml'),
  folders: YAML.safe_load_file('./db/seeds/folders_seeds.yml')
}.freeze
