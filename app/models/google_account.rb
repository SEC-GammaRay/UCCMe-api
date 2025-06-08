# frozen_string_literal: true

module UCCMe 
    # Maps Google details to attributes 
    class GoogleAccount 
        def initialize(google_account)
            @google_account = google_account
        end 
        
        def username 
            @google_account['name'] || @google_account['given_name'] || 'Unknown'
        end 

        def email 
            @google_account['email']
        end 
    end
end