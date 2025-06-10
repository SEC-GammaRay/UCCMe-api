# frozen_string_literal: true

module UCCMe
  # Add a collaborator to another owner's existing folder
  class GetFolderQuery
    # Error for owner cannot be collaborator
    class ForbiddenError < StandardError
      def message
        'You are not allowed to access that folder'
      end
    end

    # Error for cannot find a folder
    class NotFoundError < StandardError
      def message
        'We could not find that folder'
      end
    end

    def self.call(auth:, folder_id:)
      folder = Folder.first(id: folder_id)
      raise NotFoundError unless folder

      policy = FolderPolicy.new(auth.account, folder, auth.scope)
      raise ForbiddenError unless policy.can_view?

      folder.full_details.merge(policies: policy.summary)
    end
  end
end
