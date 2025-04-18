# frozen_string_literal: true

# db/migrations/002_stored_file_create.rb
require 'sequel'

Sequel.migration do
  change do
    create_table(:stored_files) do
      primary_key :id
      foreign_key :folder_id, table: :folders
      String :filename, unique: true, null: false
      String :description, null: false
      String :content, null: false
      String :cc_types, null: false
      DateTime :created_at, default: Sequel::CURRENT_TIMESTAMP
      DateTime :updated_at, default: Sequel::CURRENT_TIMESTAMP, on_update: Sequel::CURRENT_TIMESTAMP

      unique %i[folder_id filename]
    end

    add_index(:stored_files, :filename) # rubocop:disable Sequel/ConcurrentIndex
  end
end
