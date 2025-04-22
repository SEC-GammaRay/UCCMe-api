# frozen_string_literal: true

require 'roda'
require 'figaro'
require 'sequel'

# require_relative 'app/lib/secure_db'

# Configuration for the API
module UCCMe
  # Api class handles environment configuration and database connections
  class Api < Roda
    plugin :environments

    # Environment variables setup
    Figaro.application = Figaro::Application.new(
      environment: environment,
      path: File.expand_path('config/secrets.yml')
    )
    Figaro.load

    # Make the environment variables accessible to other classes
    def self.config = Figaro.env

    # Connect and make the database accessible to other classes
    db_url = ENV.delete('DATABASE_URL')
    DB = Sequel.connect("#{db_url}?encoding=utf8")

    # Class method to access the database
    def self.DB = DB # rubocop:disable Naming/MethodName

    # Development and test configurations
    configure :development, :test do
      require 'pry'

      # Database key setup
      # SecureDB.setup(ENV.delete('DB_KEY'))
    end
  end
end
