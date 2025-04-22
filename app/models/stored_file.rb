# frozen_string_literal: true

require 'fileutils'
require 'json'
require 'base64'
require 'rbnacl'
require 'sequel'

module UCCMe
  # top level
  class StoredFile < Sequel::Model
    many_to_one :folder
    plugin :timestamps, update_on_create: true
    plugin :whitelist_security
    set_allowed_columns :filename, :description, :content

    def filename=(name)
      self.filename_secure = SecureDB.encrypt(name)
    end

    def filename
      SecureDB.decrypt(filename_secure)
    end

    def cc_types=(types)
      self.cc_types_secure = SecureDB.encrypt(types)
    end

    def cc_types
      SecureDB.decrypt(cc_types_secure)
    end

    def to_json(options = {})
      JSON({
             type: 'file',
             id: id,
             filename: filename,
             description: description,
             content: content,
             cc_types: cc_types
           }, options)
    end

    def self.setup
      Dir.mkdir_p(UCCMe::STORE_DIR)
    end

    def self.locate
      FileUtils.mkdir_p(UCCMe::STORE_DIR)
    end

    # CREATE
    def self.create(filename:, cc_types:, description: nil, content: nil)
      new_file = new(
        filename: filename,
        description: description,
        content: content,
        cc_types: cc_types
      )
      new_file.id = new_id
      new_file.save_changes
      new_file
    end

    # INDEX
    def self.all; end

    # def save_to_file
    #   self.class.locate
    #   ::File.write("#{UCCMe::STORE_DIR}/#{id}.txt", to_json)
    # end

    # def self.load_from_file(id)
    #   temp_json = ::File.read("#{UCCMe::STORE_DIR}/#{id}.txt")
    #   parsed = JSON.parse(temp_json)
    #   new(parsed) # 用 Sequel.new（記住這不會儲存進 DB）
    # end

    private

    def new_id
      timestamp = Time.now.to_f.to_s
      Base64.urlsafe_encode64(RbNaCl::Hash.sha256(timestamp))[0..9]
    end
  end
end
