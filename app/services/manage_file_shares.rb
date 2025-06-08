# frozen_string_literal: true

module UCCMe
  # Service for file owners to manage their file shares - extracts auth_scope automatically
  class ManageFileShares
    class ForbiddenError < StandardError
      def message
        'You are not allowed to manage shares for this file'
      end
    end

    class NotFoundError < StandardError
      def message
        'File or share not found'
      end
    end

    # Get all shares for a file (for the file owner)
    def self.get_file_shares(file_id:, account:, auth: nil)
      file = StoredFile.first(id: file_id)
      raise NotFoundError unless file

      # Extract auth_scope and pass to policy
      if auth
        auth_scope = AuthScope.new(auth.scope)
        file_policy = FilePolicy.new(account, file, auth_scope)
        raise ForbiddenError unless file_policy.can_view?
      end

      # Only file owner can see all shares
      raise ForbiddenError unless file.owner == account

      shares = FileShare.where(stored_file_id: file_id)
                       .order(:created_at)
                       .all
      
      # Add status information
      shares.map do |share|
        share_hash = share.to_h
        share_hash[:attributes][:status] = share.expired? ? 'expired' : 'active'
        share_hash[:attributes][:shared_with_username] = share.shared_with.username
        share_hash
      end
    end

    # Delete a specific share
    def self.delete_share(share_id:, account:, auth: nil)
      share = FileShare.first(id: share_id)
      raise NotFoundError unless share

      file = share.stored_file
      
      # Extract auth_scope and pass to policy
      if auth
        auth_scope = AuthScope.new(auth.scope)
        file_policy = FilePolicy.new(account, file, auth_scope)
        raise ForbiddenError unless file_policy.can_share?
      end

      raise ForbiddenError unless file.owner == account

      share.destroy
      share
    end

    # Clean up expired shares for a specific file
    def self.cleanup_expired_shares(file_id:, account:, auth: nil)
      file = StoredFile.first(id: file_id)
      raise NotFoundError unless file

      # Extract auth_scope and pass to policy
      if auth
        auth_scope = AuthScope.new(auth.scope)
        file_policy = FilePolicy.new(account, file, auth_scope)
        raise ForbiddenError unless file_policy.can_share?
      end

      # Only file owner can cleanup
      raise ForbiddenError unless file.owner == account

      expired_shares = FileShare.where(stored_file_id: file_id)
                               .where { expires_at < Time.now }
      
      count = expired_shares.count
      expired_shares.destroy if count > 0
      
      count
    end

    # Clean up all expired shares for an account's files
    def self.cleanup_all_expired_shares(account:, auth: nil)
      file_ids = account.owned_storedfiles.map(&:id)
      
      expired_shares = FileShare.where(stored_file_id: file_ids)
                               .where { expires_at < Time.now }
      
      count = expired_shares.count
      expired_shares.destroy if count > 0
      
      count
    end
  end
end
