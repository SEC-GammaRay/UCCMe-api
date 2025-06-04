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

    def self.call(req_username:, collab_email:, folder_id:)
      account = Account.first(username: req_username)
      folder = Folder.first(id: folder_id)
      collaborator = Account.first(email: collab_email)

      policy = CollaborationRequestPolicy.new(folder, account, collaborator)
      raise ForbiddenError unless policy.can_remove?

      folder.remove_collaborator(collaborator)
      collaborator
    end
  end
end
