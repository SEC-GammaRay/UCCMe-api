# frozen_string_literal: true

require 'sequel'
require 'json'
require_relative 'password'

module UCCMe
  # Models the owner of the file
  class Account < Sequel::Model
    one_to_many :owned_storedfiles, class: :'UCCMe::StoredFile', key: :owner_id
    # one_to_many :shared_storedfiles, class: :'UCCMe::ShareFile', key: :sharer_id, conditions: { sharer_type: 'Account' }
    # many_to_many :teams, class: :'UCCMe::Team', join_table: :team_members, left_key: :owner_id, right_key: :team_id

    # destroy or delete when owner is deleted
    plugin :association_dependencies,
          owned_storedfiles: :destroy
          # shared_storedfiles: :delete
          # teams: :nullify

    # attributes that can be written to
    plugin :whitelist_security
    set_allowed_columns :ownername, :email, :password

    plugin :timestamps, update_on_create: true

    def password=(new_password)
      self.password_digest = Password.digest(new_password)
    end

    def password?(try_password)
      password = UCCMe::Password.from_digest(password_digest)
      password.correct?(try_password)
    end

    def to_json(options = {})
      JSON(
        {
          type: 'owner',
          id: id,
          ownername: ownername,
          email: email
        }, options
      )
    end
  end
end