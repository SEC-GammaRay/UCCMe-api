# frozen_string_literal: true

module UCCMe
  # Add a collaborator to another owner's existing folder
  class AddCollaborator
    # Error for owner cannot be collaborator
    class ForbiddenError < StandardError
      def message
        'You are not allowed to invite that person as collaborator'
      end
    end

    def self.call(account:, folder_id:, collab_email:)
      invitee = Account.first(email: collab_email)
      folder = Folder.first(id: folder_id)
      policy = CollaborationRequestPolicy.new(folder, account, invitee)
      raise ForbiddenError unless policy.can_invite?

      folder.add_collaborator(invitee)
      invitee
    end
  end
end
