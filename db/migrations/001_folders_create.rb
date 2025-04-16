require 'sequel'

Sequel.migration do
  change do
    create_table(:folders) do
      primary_key :id
      String :filename, null: false
      String :description, null: false
      String :content, null: false
      String :cc_types, null: false
      DateTime :created_at, default: Sequel::CURRENT_TIMESTAMP
    end
  end
end