# frozen_string_literal: true

module UCCMe
  # Add a collaborator to another owner's existing folder
  class AddCollaboratorToFolder
    # Error for owner cannot be collaborator
    class OwnerNotCollaboratorError < StandardError
      def message = 'Owner cannot be collaborator of folder'
    end

    # Error for folder not found
    class FolderNotFoundError < StandardError
      def message = 'Folder not found'
    end

    def self.call(email:, folder_id:)
      collaborator = Account.first(email:)
      folder = Folder.first(id: folder_id)

      raise FolderNotFoundError unless folder
      raise(OwnerNotCollaboratorError) if folder.owner&.id == collaborator.id

      folder.add_collaborator(collaborator)
    end
  end
end
