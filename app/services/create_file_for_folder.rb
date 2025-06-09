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


      new_file = StoredFile.new
      new_file.set(file_data)
      new_file.folder_id = folder.id
      new_file.owner_id = folder.owner_id
      new_file.save_changes
      new_file
    end
  end
end
