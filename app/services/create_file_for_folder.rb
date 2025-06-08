# frozen_string_literal: true

module UCCMe
  # Service to add a file to a folder
  class CreateFileForFolder
    # Folder not found error
    class FolderNotFoundError < StandardError
      def message = 'Folder not found'
    end

    def self.call(folder_id:, file_data:)
      folder = Folder.first(id: folder_id)
      raise FolderNotFoundError unless folder

      new_file = StoredFile.new
      new_file.set(file_data)
      new_file.folder_id = folder.id
      new_file.owner_id = folder.owner_id
      new_file.save_changes
      new_file
    end
  end
end
