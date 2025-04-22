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

    # def save_to_file
    #   self.class.locate
    #   ::File.write("#{UCCMe::STORE_DIR}/#{id}.txt", to_json)
    # end

    # def self.load_from_file(id)
    #   temp_json = ::File.read("#{UCCMe::STORE_DIR}/#{id}.txt")
    #   parsed = JSON.parse(temp_json)
    #   new(parsed) # 用 Sequel.new（記住這不會儲存進 DB）
    # end

    # def self.all_ids
    #   Dir.glob("#{UCCMe::STORE_DIR}/*.txt").map do |file|
    #     file.match(%r{#{Regexp.quote(UCCMe::STORE_DIR)}/(.*)\.txt})[1]
    #   end
    # end

    # private

    # def new_id
    #   timestamp = Time.now.to_f.to_json
    #   Base64.urlsafe_encode64(RbNaCl::Hash.sha256(timestamp))[0..9]
    # end
  end
end
