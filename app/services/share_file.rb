# frozen_string_literal: true

require 'securerandom'

module UCCMe
  # Service to share a file with another user
  class ShareFile
    class ForbiddenError < StandardError
      def message
        'You are not allowed to share this file'
      end
    end

    class NotFoundError < StandardError
      def message
        'File or user not found'
      end
    end

    def self.call(account:, file_id:, share_with_email:, permissions:, expires_at: nil, auth_scope: nil)
      file = StoredFile.first(id: file_id)
      raise NotFoundError unless file

      share_with = Account.first(email: share_with_email)
      raise NotFoundError unless share_with

      # Use default auth_scope if not provided
      auth_scope ||= AuthScope.new(AuthScope::EVERYTHING)

      policy = FilePolicy.new(account, file, auth_scope)
      raise ForbiddenError unless policy.can_share?

      # Don't allow sharing with self
      raise ForbiddenError if account == share_with

      # Check if share already exists
      existing_share = FileShare.where(
        stored_file_id: file.id,
        shared_with_id: share_with.id
      ).first

      if existing_share
        # Update existing share
        existing_share.update(
          permissions: JSON.generate(permissions),
          expires_at: expires_at
        )
        existing_share
      else
        # Create new share
        share_token = SecureRandom.urlsafe_base64(32)
        
        FileShare.create(
          stored_file_id: file.id,
          owner_id: account.id,
          shared_with_id: share_with.id,
          permissions: JSON.generate(permissions),
          expires_at: expires_at,
          share_token: share_token
        )
      end
    end
  end
end
