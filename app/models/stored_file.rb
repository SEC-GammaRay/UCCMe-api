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

    def before_create
      self.id ||= new_id
      super
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
    #   new(parsed) # 注意：這不會寫入 DB
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
