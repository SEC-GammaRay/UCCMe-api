# frozen_string_literal: true

require 'fileutils'
require 'json'
require 'base64'
require 'rbnacl'
require 'sequel'

module UCCMe
  STORE_DIR = 'db/store'
  # top level
  class Folder < Sequel::Model
    one_to_many :stored_files
    plugin :association_dependencies, stored_files: :destroy
    plugin :timestamps, update_on_create: true
    plugin :whitelist_security
    set_allowed_columns :foldername, :description

    def foldername=(name)
      self.foldername_secure = SecureDB.encrypt(name)
    end

    def foldername
      SecureDB.decrypt(foldername_secure)
    end

    def description=(plaintext)
      self.description_secure = SecureDB.encrypt(plaintext)
    end

    def description
      SecureDB.decrypt(description_secure)
    end

    def to_json(options = {})
      JSON({
             type: 'folder',
             id: id,
             foldername: foldername,
             description: description
           }, options)
    end

    def self.setup
      Dir.mkdir_p(UCCMe::STORE_DIR)
    end

    def self.locate
      FileUtils.mkdir_p(UCCMe::STORE_DIR)
    end

    # CREATE (Create a new folder)
    def self.create(foldername:, description: nil)
      folder = new
      folder.foldername = foldername
      folder.description = description
      folder.save_changes
      folder
    end

    # CREATE (Add a file to a folder)
    def add_stored_file(filename:, cc_types:, content: nil, description: nil)
      StoredFile.create(
        filename: filename,
        cc_types: cc_types,
        description: description,
        content: content
      )
    end

    # INDEX (Get all folders)
    def self.index
      all
    end

    # READ (Get a folder by ID)
    def self.read(id)
      find(id: id)
    end

    # UPDATE (Update a folder)
    def update(foldername: nil, description: nil)
      self.foldername = foldername if foldername
      self.description = description if description
      save_changes
    end

    # DESTROY (Delete a folder)

    private

    def new_id
      timestamp = Time.now.to_f.to_json
      Base64.urlsafe_encode64(RbNaCl::Hash.sha256(timestamp))[0..9]
    end
  end
end
