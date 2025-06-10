# frozen_string_literal: true

module UCCMe
  # Leave from another owner's existing folder
  class LeaveFolder
    # Error for owner cannot leave the folder
    class ForbiddenError < StandardError
      def message
        'You are not allowed to leave your own folder'
      end
    end

    def self.call(auth:, folder_id:)
      folder = Folder.first(id: folder_id)
      collaborator = auth.account

      policy = FolderPolicy.new(
        collaborator, folder, auth.scope
      )
      raise ForbiddenError unless policy.can_leave?

      folder.remove_collaborator(collaborator)
      folder
    end
  end
end
