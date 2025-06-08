# frozen_string_literal: true

require 'sequel'

Sequel.migration do
  change do
    create_table(:file_shares) do
      primary_key :id
      foreign_key :stored_file_id, :stored_files, null: false
      foreign_key :owner_id, :accounts, null: false
      foreign_key :shared_with_id, :accounts, null: false

      String :permissions, null: false # JSON array: ['view'] or ['view', 'copy']
      String :share_token, unique: true # Unique token for accessing shared file
      DateTime :expires_at # NULL means no expiration

      DateTime :created_at
      DateTime :updated_at

      index :share_token
      index :expires_at
      unique %i[stored_file_id shared_with_id]
    end
  end
end
