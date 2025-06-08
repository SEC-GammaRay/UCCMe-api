# frozen_string_literal: true

module UCCMe
  # Service to add a file to a folder
  class CreateFile
    # Error for illegal file creation requests
    class IllegalRequestError < StandardError
      def message
        'Cannot create a file with those attributes'
      end
    end

    # Error for forbidden requests
    class ForbiddenError < StandardError
      def message
        'You are not allowed to create a file in that folder'
      end
    end

    def self.call(account:, folder_id:, file_data:)
      folder = Folder.first(id: folder_id)
      raise ForbiddenError unless folder

      policy = FolderPolicy.new(account, folder)
      raise ForbiddenError unless policy.can_add_files?

      # Check if filename already exists in folder
      existing_file = StoredFile.where(
        folder_id: folder_id,
        filename: file_data[:filename]
      ).first
      
      raise IllegalRequestError if existing_file

      folder.add_stored_file(file_data)
    rescue Sequel::MassAssignmentRestriction
      raise IllegalRequestError
    end
  end
end
