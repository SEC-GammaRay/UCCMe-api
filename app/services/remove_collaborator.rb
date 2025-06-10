# frozen_string_literal: true

module UCCMe
  # Remove a collaborator from another owner's existing folder
  class RemoveCollaborator
    # Error for owner cannot be collaborator
    class ForbiddenError < StandardError
      def message
        'You are not allowed to remove that person'
      end
    end

    def self.call(auth:, collab_email:, folder_id:)
      folder = Folder.first(id: folder_id)
      collaborator = Account.first(email: collab_email)

      policy = CollaborationRequestPolicy.new(
        folder, auth.account, collaborator, auth.scope
      )
      raise ForbiddenError unless policy.can_remove?

      folder.remove_collaborator(collaborator)
      collaborator
    end
  end
end
