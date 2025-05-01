# frozen_string_literal: true

require 'roda'
require 'figaro'
require 'sequel'
require 'logger'

require_relative '../app/lib/secure_db'

# Configuration for the API
module UCCMe
  # Api class handles environment configuration and database connections
  class Api < Roda
    plugin :environments

    # rubocop:disable Lint/ConstantDefinitionInBlock
    configure do
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
      DB.run('PRAGMA foreign_keys = ON') # Ensure SQLite has foreign key constraints enabled

      # Class method to access the database
      def self.DB = DB # rubocop:disable Naming/MethodName

      # Load cryto key
      SecureDB.setup(ENV.delete('DB_KEY'))

      # Custom events Logger
      LOGGER = Logger.new($stdout)
      def self.logger = LOGGER
    end
    # rubocop:enable Lint/ConstantDefinitionInBlock

    # HTTP Request logging
    configure :development, :production do
      plugin :common_logger, $stdout
    end

    configure :development, :test do
      require 'pry'
    end

    configure :test do
      logger.level = Logger::ERROR
    end
  end
end
