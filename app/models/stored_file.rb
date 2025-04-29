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
    plugin :prepared_statements # Add prepared statement support for extra security
    set_allowed_columns :filename, :description, :content, :cc_types

    def_column_accessor :filename_secure, :cc_types_secure

    def filename=(name)
      self.filename_secure = SecureDB.encrypt(name)
    end

    def filename
      SecureDB.decrypt(filename_secure)
    end

    def cc_types=(types)
      self.cc_types_secure = SecureDB.encrypt(types.join(','))
    end

    def cc_types
      value = SecureDB.decrypt(cc_types_secure)
      value&.include?(',') ? value.split(',') : value
    end

    # def before_create
    #   self.id ||= new_id
    #   super
    # end

    # rubocop:disable Metrics/MethodLength
    def to_json(options = {})
      JSON(
        {
          data: {
            type: 'file',
            attributes: {
              id: id,
              filename: filename,
              description: description,
              content: content,
              cc_types: cc_types
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

    # CREATE (Create a new file)
    def self.create(file_data = {})
      # Initialize new file with provided or default values
      new_file = new
      new_file.filename = file_data[:filename]
      new_file.description = file_data[:description]
      new_file.content = file_data[:content]
      new_file.cc_types = file_data[:cc_types]
      new_file.folder_id = file_data[:folder_id]
      # Save and return the file
      new_file.save_changes
      new_file
    end

    # INDEX (optional filter by foldername)
    def self.all(foldername = nil)
      if foldername
        where(foldername: foldername)
      else
        where(foldername: nil)
      end
    end

    # READ (get file by id)
    def self.read(id)
      find(id: id)
    end

    # UPDATE (Update file attributes)
    def update(filename: nil, cc_types: nil, description: nil, content: nil)
      self.filename = filename if filename
      self.cc_types = cc_types if cc_types
      self.description = description if description
      self.content = content if content
      save_changes
    end

    # DESTROY (Delete file)

    private

    def new_id
      timestamp = Time.now.to_f.to_s
      Base64.urlsafe_encode64(RbNaCl::Hash.sha256(timestamp))[0..9]
    end
  end
end
