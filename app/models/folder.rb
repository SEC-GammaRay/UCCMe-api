# frozen_string_literal: true

require 'fileutils'
require 'json'
require 'base64'
require 'rbnacl'
require 'sequel'

module UCCMe
    STORE_DIR = 'db/local'

    # store properties 
    class Folder < Sequel::Model(:folders) 
        one_to_many :file
        plugin :association_dependencies, :file => :destroy # delete files when folder is deleted
        plugin :timestamps, update_on_create: true

        def initialize(new_folder)
            @id = new_folder['id'] || new_id
            @foldername = new_folder['foldername']
            @description = new_folder['description']
        end 

        attr_reader :id, :filename, :description

        def to_json(options = {})
            JSON(
                {
                    type: 'folder',
                    id:,
                    folderame:,
                    description:,
                },
                options
            )
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