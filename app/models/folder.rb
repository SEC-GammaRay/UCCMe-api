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
    many_to_one :owner, class: :'UCCMe::Account'
    many_to_many :collaborators,
                 class: :'UCCMe::Account',
                 join_table: :accounts_folders,
                 left_key: :folder_id, right_key: :collaborator_id
    plugin :association_dependencies,
           stored_files: :destroy,
           collaborators: :nullify
    plugin :timestamps, update_on_create: true
    plugin :whitelist_security
    plugin :prepared_statements # Add prepared statement support for extra security
    set_allowed_columns :foldername, :description, :owner_id

    # def_column_accessor :foldername_secure, :description_secure

    # def before_create
    #   self.id ||= new_id
    #   super
    # end

    # def foldername=(name)
    #   self.foldername_secure = SecureDB.encrypt(name)
    # end

    # def foldername
    #   SecureDB.decrypt(foldername_secure)
    # end

    def description=(plaintext)
      self.description_secure = SecureDB.encrypt(plaintext)
    end

    def description
      SecureDB.decrypt(description_secure)
    end

    def to_h
      {
        type: 'folder',
        attributes: {
          id:,
          foldername:,
          description:
        }
      }
    end

    def self.setup
      Dir.mkdir_p(UCCMe::STORE_DIR)
    end

    def self.locate
      FileUtils.mkdir_p(UCCMe::STORE_DIR)
    end

    def full_details
      to_h.merge(
        relationships: {
          owner:,
          collaborators:,
          stored_files:
        }
      )
    end

    def to_json(options = {})
      JSON(to_h, options)
    end
  end
end
