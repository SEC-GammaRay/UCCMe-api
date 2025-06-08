# frozen_string_literal: true

require 'fileutils'
require 'json'
require 'base64'
require 'rbnacl'
require 'sequel'

module UCCMe
  # top level
  class StoredFile < Sequel::Model
    many_to_one :owner, class: :'UCCMe::Account'

    many_to_many :collaborators,
                 class: :'UCCMe::Account',
                 join_table: :accounts_stored_files,
                 left_key: :file_id, right_key: :collaborator_id

    many_to_one :folder
    plugin :timestamps, update_on_create: true
    plugin :whitelist_security
    plugin :prepared_statements # Add prepared statement support for extra security
    set_allowed_columns :filename, :description, :s3_path, :cc_types, :owner_id

    # def_column_accessor :filename_secure, :cc_types_secure

    # def before_create
    #   self.id ||= new_id
    #   super
    # end

    # def filename=(name)
    #   self.filename_secure = SecureDB.encrypt(name)
    # end

    # def filename
    #   SecureDB.decrypt(filename_secure)
    # end

    def description=(plaintext)
      self.description_secure = SecureDB.encrypt(plaintext)
    end

    def description
      SecureDB.decrypt(description_secure)
    end

    def cc_types=(types)
      self.cc_types_secure = SecureDB.encrypt(types.join(','))
    end

    def cc_types
      value = SecureDB.decrypt(cc_types_secure)
      value&.include?(',') ? value.split(',') : value
    end

    def to_h # rubocop:disable Metrics/MethodLength
      {
        type: 'file',
        attributes: {
          id:,
          filename:,
          description:,
          s3_path:,
          cc_types:
        },
        include: {
          folder:
        }
      }
    end

    def to_json(options = {})
      JSON(to_h, options)
    end

    def self.setup
      Dir.mkdir_p(UCCMe::STORE_DIR)
    end

    def self.locate
      FileUtils.mkdir_p(UCCMe::STORE_DIR)
    end
  end
end
