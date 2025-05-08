# frozen_string_literal: true

Sequel.seed(:development) do
  def run
    puts 'Seeding accounts, folders, stored_files'
    create_accounts
    create_owned_folders
    create_stored_files
    add_folder_collaborators
  end
end

require 'yaml'
DIR = File.dirname(__FILE__)
ACCOUNTS_INFO = YAML.load_file("#{DIR}/accounts_seeds.yml")
OWNERS_INFO = YAML.load_file("#{DIR}/owners_folders_seeds.yml")
FOLDERS_INFO = YAML.load_file("#{DIR}/folders_seeds.yml")
FILES_INFO = YAML.load_file("#{DIR}/stored_files_seeds.yml")
CONTRIB_INFO = YAML.load_file("#{DIR}/folders_collaborators.yml")

def create_accounts
  ACCOUNTS_INFO.each do |account_info|
    UCCMe::Account.create(account_info)
  end
end

def create_owned_folders
  OWNERS_INFO.each do |owner|
    account = UCCMe::Account.first(username: owner['username'])
    owner['folder_name'].each do |folder_name|
      folder_data = FOLDERS_INFO.find { |folder| folder['foldername'] == folder_name }
      UCCMe::CreateFolderForOwner.call(
        owner_id: account.id, folder_data: folder_data
      )
    end
  end
end

def create_stored_files
  file_info_each = FILES_INFO.each
  folders_cycle = UCCMe::Folder.all.cycle
  loop do
    file_info = file_info_each.next
    folder = folders_cycle.next
    UCCMe::CreateFileForFolder.call(
      folder_id: folder.id, file_data: file_info
    )
  end
end

def add_folder_collaborators
  contrib_info = CONTRIB_INFO
  contrib_info.each do |contrib|
    folder = UCCMe::Folder.first(foldername: contrib['folder_name'])
    contrib['collaborator_email'].each do |email|
      UCCMe::AddCollaboratorToFolder.call(
        email:, folder_id: folder.id
      )
    end
  end
end
