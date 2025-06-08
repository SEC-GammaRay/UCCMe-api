# frozen_string_literal: true

module UCCMe
  # Remove file share based on RemoveCollaborator logic
  class RemoveFileShare
    class ForbiddenError < StandardError
      def message
        'You are not allowed to remove this share'
      end
    end

    class ShareNotFoundError < StandardError
      def message
        'No active share found for this user'
      end
    end


    def self.call(account:, file_id:, user_email:)

      target_user = Account.first(email: user_email)
      file = StoredFile.first(id: file_id)
      
      raise ForbiddenError unless target_user
      raise ForbiddenError unless file
      raise ForbiddenError unless file.owner == account

      policy = FileSharingRequestPolicy.new(file, account, target_user)
      raise ForbiddenError unless policy.can_remove_share?

      active_shares = file.active_shares_for_user(target_user)
      raise ShareNotFoundError if active_shares.empty?

      file.remove_share(user_email)
      
      {
        message: 'Share removed successfully',
        removed_user: user_email,
        file: file.to_h
      }
    end
  end

  # Update file share permission
  class UpdateFileSharePermission
    class ForbiddenError < StandardError
      def message
        'You are not allowed to update this share'
      end
    end

    class ShareNotFoundError < StandardError
      def message
        'No active share found for this user'
      end
    end

    class InvalidPermissionError < StandardError
      def message
        'Invalid permission. Must be "view" or "copy"'
      end
    end

    def self.call(account:, file_id:, user_email:, new_permission:)

      target_user = Account.first(email: user_email)
      file = StoredFile.first(id: file_id)

      raise ForbiddenError unless target_user
      raise ForbiddenError unless file
      raise ForbiddenError unless file.owner == account

      policy = FileSharingRequestPolicy.new(file, account, target_user)
      raise ForbiddenError unless policy.can_update_permission?

      normalized_permission = new_permission.to_s.downcase
      raise InvalidPermissionError unless ['view', 'copy'].include?(normalized_permission)

      active_shares = file.active_shares_for_user(target_user)
      raise ShareNotFoundError if active_shares.empty?

      file.update_share_permission(user_email, normalized_permission)
      
      {
        message: 'Share permission updated successfully',
        updated_user: user_email,
        new_permission: normalized_permission,
        file: file.to_h
      }
    end
  end
end
