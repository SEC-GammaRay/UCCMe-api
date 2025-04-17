# frozen_string_literal: true

ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'
require 'minitest/rg'
require 'yaml'
require_relative 'test_load_all'

def wipe_database
  app.DB[:files].delete
  # app.DB[:folders].delete
end

DATA = {} # rubocop:disable Style/MutableConstant
DATA[:files] = YAML.safe_load_file('db/seeds/document_seeds.yml')
# DATA[:folders] = YAML.safe_load_file('db/seeds/project_seeds.yml')
