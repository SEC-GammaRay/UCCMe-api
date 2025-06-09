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

def scoped_auth(auth_token)
  token = AuthToken.new(auth_token)
  account_data = token.payload['attributes']

  account = UCCMe::Account.first(username: account_data['username'])
  UCCMe::AuthorizedAccount.new(account, token.scope)
end

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
      account.add_owned_folder(folder_data)
    end
  end
end

def create_stored_files # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
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

    auth_token = AuthToken.create(folder.owner)
    auth = scoped_auth(auth_token)

    UCCMe::CreateFileForFolder.call(
      auth: auth, folder_id: folder.id, file_data: file_data
    )
  end
end

def add_folder_collaborators # rubocop:disable Metrics/MethodLength
  contrib_info = CONTRIB_INFO
  contrib_info.each do |contrib|
    folder = UCCMe::Folder.first(foldername: contrib['folder_name'])

    auth_token = AuthToken.create(folder.owner)
    auth = scoped_auth(auth_token)

    contrib['collaborator_email'].each do |email|
      UCCMe::AddCollaborator.call(
        account: folder.owner,
        # auth: auth,
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
    rescue StandardError => error
      puts "  Failed to create file share: #{error.message}"
    end
  end
end
