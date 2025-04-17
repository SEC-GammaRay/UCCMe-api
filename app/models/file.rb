# frozen_string_literal: true

require 'fileutils'
require 'json'
require 'base64'
require 'rbnacl'
require 'sequel'

module UCCMe
  STORE_DIR = 'db/local'

  # store properties
  class Filee < Sequel::Model(:files)
    many_to_one :folder
    plugin :timestamps, update_on_create: true

    def initialize(new_file) # rubocop:disable Lint/MissingSuper
      @id = new_file['id'] || new_id
      @filename = new_file['filename']
      @description = new_file['description']
      @content = new_file['content']
      @cc_types = new_file['cc_types']
    end

    attr_reader :id, :filename, :description, :content, :cc_types

    def to_json(options = {})
      JSON({ type: 'file', id:, filename:, description:, content:, cc_types: }, options)
    end

    # set up location to store file
    def self.locate
      FileUtils.mkdir_p(UCCMe::STORE_DIR)
    end

    # create
    def save
      ::File.write("#{UCCMe::STORE_DIR}/#{id}.txt", to_json)
    end

    # read 1 file
    def self.find(id)
      temp_json = ::File.read("#{UCCMe::STORE_DIR}/#{id}.txt")
      Property.new JSON.parse(temp_json)
    end

    def self.all
      Dir.glob("#{UCCMe::STORE_DIR}/*.txt").map do |file|
        file.match(%r{#{Regexp.quote(UCCMe::STORE_DIR)}/(.*)\.txt})[1] # retrieve index
        # file.match(%r{#{Regexp.quote(UCCMe::STORE_DIR)}/(.*)\.txt})[2] # retrieve filename
      end
    end

    private

    def new_id
      timestamp = Time.now.to_f.to_json
      Base64.urlsafe_encode64(RbNaCl::Hash.sha256(timestamp))[0..9]
    end
  end
end
