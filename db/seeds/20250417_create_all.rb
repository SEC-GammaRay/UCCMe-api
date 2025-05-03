# frozen_string_literal: true

Sequel.seed(:development) do
  def run
    puts 'Seeding accounts, folders, files'
    create_accounts
    create_owned_folders
    create_stored_files
    add_collaborators
    add_file_collaborators
  end
end

require 'yaml'
DIR = File.dirname(__FILE__)
ACCOUNTS_INFO = YAML.load_file("#{DIR}/accounts_seeds.yml")
OWNER_INFO = YAML.load_file("#{DIR}/owners_folders.yml")
FOLDER_INFO = YAML.load_file("#{DIR}/folders_seeds.yml")
FILE_INFO = YAML.load_file("#{DIR}/stored_files_seeds.yml")
COLLAB_INFO = YAML.load_file("#{DIR}/files_collaborators.yml")

def create_accounts
  ACCOUNTS_INFO.each do |account_info|
    UCCMe::Account.create(account_info)
  end
end

# rubocop:disable Metrics/MethodLength
def create_owned_folders
  OWNER_INFO.each do |owner|
    UCCMe::Account.first(username: owner['username'])
    owner['folder_name'].each do |folder_name|
      folder_data = FOLDER_INFO.find { |folder| folder['foldername'] == folder_name }
      UCCMe::CreateFolderForOwner.call(
        {
          foldername: folder_data['foldername'],
          description: folder_data['description']
        }
      )
    end
  end
end
# rubocop:enable Metrics/MethodLength

# rubocop:disable Metrics/MethodLength
def create_stored_files
  file_info_each = FILE_INFO.each
  folders_cycle = UCCMe::Folder.all.cycle
  loop do
    file_info = file_info_each.next
    folder = folders_cycle.next
    UCCMe::CreateFileForFolder.call(
      folder_id: folder.id,
      file_data: {
        filename: file_info['filename'],
        description: file_info['description'],
        content: file_info['content'],
        cc_types: file_info['cc_types']
      }
    )
  end
end
# rubocop:enable Metrics/MethodLength

def add_collaborators
  collab_info = COLLAB_INFO
  collab_info.each do |collab|
    folder = UCCMe::Folder.first(foldername: collab['folder_name'])
    collab['collaborator_email'].each do |email|
      UCCMe::AddCollaboratorToFolder.call(
        email: email,
        folder_id: folder.id
      )
    end
  end
end

def add_file_collaborators
  file_collab_info = YAML.load_file("#{DIR}/files_collaborators.yml")
  file_collab_info.each do |collab|
    file = UCCMe::StoredFile.first(filename: collab['file_name'])
    collab['collaborator_email'].each do |email|
      account = UCCMe::Account.first(email: email)
      file.add_collaborator(account) if file && account
    end
  end
end
