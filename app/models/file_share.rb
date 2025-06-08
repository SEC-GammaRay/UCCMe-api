# frozen_string_literal: true

require 'sequel'
require 'json'

module UCCMe
  # Model for sharing files with time limits
  class FileShare < Sequel::Model
    many_to_one :stored_file
    many_to_one :owner, class: :'UCCMe::Account'
    many_to_one :shared_with, class: :'UCCMe::Account'

    plugin :timestamps, update_on_create: true
    plugin :whitelist_security
    set_allowed_columns :stored_file_id, :owner_id, :shared_with_id, 
                       :expires_at, :permissions, :share_token

    def expired?
      expires_at && Time.now > expires_at
    end

    def active?
      !expired?
    end

    def can_view?
      active? && (permissions.include?('view') || permissions.include?('copy'))
    end

    def can_copy?
      active? && permissions.include?('copy')
    end

    def to_h
      {
        type: 'file_share',
        attributes: {
          id: id,
          stored_file_id: stored_file_id,
          shared_with_id: shared_with_id,
          expires_at: expires_at,
          permissions: permissions,
          active: active?
        }
      }
    end

    def to_json(options = {})
      JSON(to_h, options)
    end
  end
end
