<<<<<<< HEAD
# frozen_string_literal: true

require './require_app'
require_app

run UCCMe::Api.freeze.app
=======
require 'pry'
require './app/controllers/app'
require_app 
run UCCMe::Api.freeze.app 

binding.pry
>>>>>>> cac335c (fix: fix rake file)
