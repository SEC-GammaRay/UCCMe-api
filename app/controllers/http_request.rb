# frozen_string_literal: true 

module UCCMe 
    class HttpRequest
        def initialize(roda_routing)
            @routing = roda_routing
        end 
        
        def secure? 
            raise 'Secure schema not configured' unless Api.config.SECURE_SCHEME

            @routing.scheme.casecmp(Api.config.SECURE_SCHEME).zero?
        end 

        def body_data 
            JSON.parse(@routing.body.read, symbolize_names: true)
        end 
    end 
end 

        