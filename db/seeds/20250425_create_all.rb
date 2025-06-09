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
OWNERS_INFO = YAML.load_file("#{DIR}/owners_folders.yml")
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

def create_stored_files # rubocop:disable Metrics/MethodLength
  file_info_each = FILES_INFO.each
  folders_cycle = UCCMe::Folder.all.cycle
  loop do
    file_info = file_info_each.next
    folder = folders_cycle.next

    filename = file_info['filename']
    local_path = File.join('uploads', filename)
    file_content = File.binread(local_path)

    s3_url = FileStorageHelper.upload(file: file_content, filename: filename)
    file_data = file_info.merge('s3_path' => s3_url)

    UCCMe::CreateFileForFolder.call(
      account: folder.owner, folder_id: folder.id, file_data: file_data
    )
  end
end

def add_folder_collaborators # rubocop:disable Metrics/MethodLength
  contrib_info = CONTRIB_INFO
  contrib_info.each do |contrib|
    folder = UCCMe::Folder.first(foldername: contrib['folder_name'])
    contrib['collaborator_email'].each do |email|
      account = folder.owner
      UCCMe::AddCollaborator.call(
        account: account,
        folder_id: folder.id,
        collab_email: email
      )
    end
  end
end
