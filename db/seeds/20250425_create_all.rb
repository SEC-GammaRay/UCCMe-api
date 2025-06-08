# frozen_string_literal: true

Sequel.seed(:development) do
  def run
    puts 'Seeding accounts, folders, stored_files, file_shares'
    create_accounts
    create_owned_folders
    create_stored_files
    add_folder_collaborators
    create_file_shares
  end
end

require 'yaml'
DIR = File.dirname(__FILE__)
ACCOUNTS_INFO = YAML.load_file("#{DIR}/accounts_seeds.yml")
OWNERS_INFO = YAML.load_file("#{DIR}/owners_folders.yml")
FOLDERS_INFO = YAML.load_file("#{DIR}/folders_seeds.yml")
FILES_INFO = YAML.load_file("#{DIR}/stored_files_seeds.yml")
CONTRIB_INFO = YAML.load_file("#{DIR}/folders_collaborators.yml")
FILE_SHARES_INFO = YAML.load_file("#{DIR}/file_shares_seeds.yml")

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
      UCCMe::AddCollaborator.call(
        account: folder.owner,
        folder_id: folder.id,
        collab_email: email
      )
    end
  end
end

def create_file_shares
  FILE_SHARES_INFO.each do |share_info|
    # Find the file by filename
    file = UCCMe::StoredFile.first(filename: share_info['stored_file_filename'])
    next unless file

    # Find owner and shared_with accounts
    owner = UCCMe::Account.first(username: share_info['owner_username'])
    shared_with = UCCMe::Account.first(email: share_info['shared_with_email'])
    
    next unless owner && shared_with
    next unless file.owner == owner # Verify ownership

    # Parse expiration date
    expires_at = share_info['expires_at'] ? Time.parse(share_info['expires_at']) : nil

    # Create the file share using the ShareFile service
    begin
      UCCMe::ShareFile.call(
        account: owner,
        file_id: file.id,
        share_with_email: shared_with.email,
        permissions: share_info['permissions'],
        expires_at: expires_at,
        auth_scope: UCCMe::AuthScope.new(UCCMe::AuthScope::EVERYTHING)
      )
      puts "  Created file share: #{file.filename} -> #{shared_with.email}"
    rescue StandardError => e
      puts "  Failed to create file share: #{e.message}"
    end
  end
end
