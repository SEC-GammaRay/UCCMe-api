# frozen_string_literal: true

module UCCMe 
    # Maps Google details to attributes 
    class GoogleAccount 
        def initilize(google_account)
            @google_account = google_account
        end 
        
        def username 
            @google_account['login'] + @google
        end 

        def email 
            @google_account['email']
        end 
    end
end