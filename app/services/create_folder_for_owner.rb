# frozen_string_literal: true

module UCCMe
  # Service to create a new folder for an owner
  class CreateFolderForOwner
    # Error for owner not found
    class OwnerNotFoundError < StandardError
      def message = 'Owner not found'
    end

     def self.call(auth:, folder_data:)
      raise ForbiddenError unless auth.scope.can_write?('folders')

      auth.account.add_owned_folder(folder_data)
    end
  end
end
