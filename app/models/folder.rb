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
    plugin :prepared_statements # Add prepared statement support for extra security
    set_allowed_columns :foldername, :description

    def_column_accessor :foldername_secure, :description_secure

    def before_create
      self.id ||= new_id
      super
    end

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

    # rubocop:disable Metrics/MethodLength
    def to_json(options = {})
      JSON(
        {
          data: {
            type: 'folder',
            attributes: {
              id: id,
              foldername: foldername,
              description: description
            }
          }
        }, options
      )
    end
    # rubocop:enable Metrics/MethodLength

    def self.setup
      Dir.mkdir_p(UCCMe::STORE_DIR)
    end

    def self.locate
      FileUtils.mkdir_p(UCCMe::STORE_DIR)
    end

    # CREATE (Create a new folder)
    def self.create(attributes = nil)
      folder = new
      folder.foldername = attributes[:foldername] || attributes['foldername']
      folder.description = attributes[:description] || attributes['description']
      folder.save_changes
      folder
    end

    # CREATE (Add a file to a folder)
    def add_stored_file(data = {})
      # StoredFile.create(
      #   # id: data[:id],
      #   filename: data[:filename],
      #   description: data[:description],
      #   content: data[:content],
      #   cc_types: data[:cc_types],
      #   folder_id: id,
      #   # created_at: data[:created_at],
      #   # updated_at: data[:updated_at]
      # )
      file = StoredFile.new
      file.set(data)
      file.folder_id = id
      file.save_changes
      file
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
      timestamp = Time.now.to_f.to_s
      Base64.urlsafe_encode64(RbNaCl::Hash.sha256(timestamp))[0..9]
    end
  end
end
