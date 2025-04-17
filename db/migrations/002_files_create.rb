# frozen_string_literal: true

require 'sequel'

Sequel.migration do
  change do
    create_table(:files) do
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

    # add index to filename
    add_index(:files, :filename) # rubocop:disable Sequel/ConcurrentIndex
  end
end
