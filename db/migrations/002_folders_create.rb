# frozen_string_literal: true

require 'sequel'

Sequel.migration do
  change do
    create_table(:folders) do
      primary_key :id
      # String :id, primary_key: true
      String :foldername_secure, null: false
      String :description_secure, null: false
      DateTime :created_at, default: Sequel::CURRENT_TIMESTAMP
    end
  end
end
