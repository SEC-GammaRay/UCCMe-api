require 'minitest/autorun'
require 'minitest/rg'
require 'rack/test'
require 'yaml'

require_relative '../app/controllers/app'
require_relative '../app/models/property'

def app 
    UCCMe::Api
end 

DATA = YAML.safe_load File.read('db/seeds/document_seeds.yml')

describe 'Test UCCMe Web API' do 
    include Rack::Test::Methods

    # delete all data before each test 
    before do 
        Dir.glob('db/local/*.txt').each { |filename| FileUtils.rm(filename) }
    end 

    # test GET request 
    it 'should find the root route' do 
        get '/'
        _(last_response.status).must_equal 200
    end 

    
    describe 'Handle files' do  

        # HAPPT TEST: files counts 
        it 'HAPPY: should be able to list all documents' do 
            UCCMe::Property.new(DATA[0]).save
            UCCMe::Property.new(DATA[1]).save

            get "api/folders/files"
            result = JSON.parse last_response.body
            puts "Result: #{result}"
            _(result['id'].count).must_equal 2
        end 
        

        # HAPPY TEST: fetch id 
        it 'HAPPY: should be able to get details of a single document' do 
            UCCMe::Property.new(DATA[1]).save
            id = Dir.glob('db/local/*.txt').first.split(%r{[/\.]})[-2]

            get "api/folders/files/#{id}"
            result = JSON.parse last_response.body 

            _(last_response.status).must_equal 200
            _(result['id']).must_equal id 
        end 

        # HAPPT TEST: create new doc 
        it 'HAPPY: should be able to create new files' do 
            req_header = {'CONTENT_TYPE' => 'application/json'}

            post "api/folders/files", DATA[1].to_json, req_header 

            _(last_response.status).must_equal 201 
        end 

        it 'HAPPY: should be 1 of 6 cc code types' do 
            
    end
end 