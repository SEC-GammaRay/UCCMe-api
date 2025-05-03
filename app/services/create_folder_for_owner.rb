# frozen_string_literal: true

module UCCMe
  # Service to create a new folder for an owner
  class CreateFolderForOwner
    # Error for owner not found
    class OwnerNotFoundError < StandardError
      def message = 'Owner not found'
    end

    def self.call(owner_id:, folder_data:)
      owner = Account.find(id: owner_id)
      raise OwnerNotFoundError unless owner

      owner.add_owned_folder(folder_data)
    end
  end
end
