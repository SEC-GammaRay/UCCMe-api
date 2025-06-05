# frozen_string_literal: true

# require 'minitest/autorun'
# require 'minitest/rg'
# require 'rack/test'
# require 'yaml'
require_relative '../spec_helper'

# require_relative '../app/controllers/app'
# require_relative '../app/models/property'

# def app
#   UCCMe::Api
# end

# VALID_CC_TYPES = [
#   'CC BY',
#   'CC BY-SA',
#   'CC BY-ND',
#   'CC BY-NC',
#   'CC BY-NC-SA',
#   'CC BY-NC-ND'
# ].freeze

# DATA = YAML.safe_load_file('db/seeds/document_seeds.yml')

describe 'Test UCCMe Web API' do
  describe 'Root Route' do
    # test GET request
    it 'should find the root route' do
      get '/'
      _(last_response.status).must_equal 200
    end
  end
end
