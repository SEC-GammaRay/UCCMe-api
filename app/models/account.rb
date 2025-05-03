# frozen_string_literal: true

require 'sequel'
require 'json'
require_relative 'password'

module UCCMe
  # Models the owner of the file
  class Account < Sequel::Model
    one_to_many :owned_storedfiles, class: :'UCCMe::StoredFile', key: :owner_id
    one_to_many :owned_folders, class: :'UCCMe::Folder', key: :owner_id
    # one_to_many :shared_storedfiles, class: :'UCCMe::ShareFile', key: :sharer_id, conditions: { sharer_type: 'Account'} # rubocop:disable Layout/LineLength
    # many_to_many :teams, class: :'UCCMe::Team', join_table: :team_members, left_key: :owner_id, right_key: :team_id
    many_to_many :collaborations, # Removed extra colon after many_to_many
                 class: :'UCCMe::StoredFile',
                 join_table: :accounts_stored_files,
                 left_key: :collaborator_id,
                 right_key: :file_id
    many_to_many :folder_collaborations,
                 class: :'UCCMe::Folder',
                 join_table: :accounts_folders,
                 left_key: :collaborator_id,
                 right_key: :folder_id

    # destroy or delete when owner is deleted
    plugin :association_dependencies,
           owned_storedfiles: :destroy,
           owned_folders: :destroy,
           # shared_storedfiles: :delete
           collaborations: :nullify,
           folder_collaborations: :nullify

    # attributes that can be written to
    plugin :whitelist_security
    set_allowed_columns :username, :email, :password

    plugin :timestamps, update_on_create: true

    def all_files
      owned_storedfiles + collaborations
    end

    def password=(new_password)
      self.password_digest = Password.digest(new_password)
    end

    def password?(try_password)
      password = UCCMe::Password.from_digest(password_digest)
      password.correct?(try_password)
    end

    def to_json(options = {})
      JSON.generate( # Changed JSON() to JSON.generate for proper JSON serialization
        {
          type: 'owner',
          id: id,
          username: username,
          email: email
        }, options
      )
    end
  end
end
