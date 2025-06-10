# frozen_string_literal: true

module UCCMe
  # Service to add a file to a folder
  class CreateFileForFolder
    # Error for not allowed to add files
    class ForbiddenError < StandardError
      def message
        'You are not allowed to add more files'
      end
    end

    # Error for requested with illegal attributes
    class IllegalRequestError < StandardError
      def message
        'Cannot create a file with those attributes'
      end
    end

    def self.call(auth:, folder_id:, file_data:)
      folder = Folder.first(id: folder_id)
      policy = FolderPolicy.new(auth.account, folder, auth.scope)
      raise ForbiddenError unless policy.can_add_files?

      folder.add_stored_file(file_data)
    rescue Sequel::MassAssignmentRestriction
      raise IllegalRequestError
    end
  end
end
