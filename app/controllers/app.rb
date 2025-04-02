require 'roda'
require 'json'

require_relative '../models/property'

module UCCMe 
    class Api < Roda 
        plugin :environments # configure blocks 
        plugin :halt # hard return from routes 

        configure do 
            Property.locate # config file storing 
        end 

        route do |routing| 
            response['Content-Type'] = 'application/json' # set http header

            routing.root do 
                {message: 'UCCMeAPI up at /api/folders'}.to_json
            end 

            routing.on 'api' do 
                routing.on 'folders' do 
                    routing.on 'files' do 

                        # GET api/folders/files/[id] (safe & idempotent)
                        routing.get String do |id|
                            Property.find(id).to_json
                        rescue StandardError 
                            routing.halt 404, {message: 'File not found'}.to_json
                        end 

                        # GET api/folders/files (safe & idempotent)
                        routing.get do 
                            output = {file_id: File.all}
                            JSON.pretty_generate(output)
                        end 

                        # POST api/folders/files (not safe & not idempotent)
                        routing.post do 
                            new_data = JSON.parse(routing.body.read)
                            new_file = Property.new(new_data)

                            if new_file.save
                                response.status = 201 
                                { message: 'Document saved', id: new_file.id }.to_json
                            else
                                routing.halt 400, {message: 'Could not save file'}.to_json
                            end 
                        end 
                    end 
                end 
            end 
        end 
    end 
end




