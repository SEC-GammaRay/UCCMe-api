# frozen_string_literal: true

require 'fileutils'
require 'json'
require 'base64'
require 'rbnacl'
require 'sequel'

module UCCMe
  # StoredFile model with multi-user sharing via cc_types
  class StoredFile < Sequel::Model
    many_to_one :owner, class: :'UCCMe::Account'
    many_to_one :folder
    
    many_to_many :collaborators,
                 class: :'UCCMe::Account',
                 join_table: :accounts_stored_files,
                 left_key: :file_id, right_key: :collaborator_id

    one_to_many :file_shares, key: :stored_file_id
           
    plugin :association_dependencies,
            file_shares: :destroy
    plugin :timestamps, update_on_create: true
    plugin :whitelist_security
    plugin :prepared_statements
    set_allowed_columns :filename, :description, :content, :cc_types, :owner_id, :folder_id

    def description=(plaintext)
      self.description_secure = SecureDB.encrypt(plaintext)
    end

    def description
      SecureDB.decrypt(description_secure)
    end

    def cc_types=(types)
      # Store as comma-separated string, supporting multiple sharing metadata
      types_array = types.is_a?(Array) ? types : [types].compact
      self.cc_types_secure = SecureDB.encrypt(types_array.join(','))
    end

    def cc_types
      value = SecureDB.decrypt(cc_types_secure)
      return [] unless value
      
      value.include?(',') ? value.split(',').map(&:strip) : [value.strip]
    end

    # Check if file is shareable (only txt and pdf files)
    def shareable?
      file_types = cc_types
      return false unless file_types
      
      # Check if file contains txt or pdf type
      allowed_types = ['txt', 'pdf', 'text', 'document']
      file_types.any? { |type| allowed_types.include?(type.downcase) }
    end

    # Check if file has any shares (active or expired)
    def has_shares?
      cc_types.any? { |type| type.downcase.start_with?('share:') }
    end

    # Get all share entries from cc_types
    def share_entries
      cc_types.select { |type| type.downcase.start_with?('share:') }.map do |share_str|
        parse_share_entry(share_str)
      end.compact
    end

    # Get only active (non-expired) shares
    def active_shares
      share_entries.select { |share| !share[:expired] }
    end

    # Get expired shares
    def expired_shares
      share_entries.select { |share| share[:expired] }
    end

    # Get shares for a specific user
    def shares_for_user(user)
      email = user.is_a?(String) ? user : user.email
      share_entries.select { |share| share[:email] == email }
    end

    # Get active shares for a specific user
    def active_shares_for_user(user)
      shares_for_user(user).select { |share| !share[:expired] }
    end

    # Check if file is shared with specific user (with any permission)
    def shared_with?(user)
      active_shares_for_user(user).any?
    end

    # Check if user has view permission
    def user_can_view?(user)
      return true if owner == user
      return true if folder&.collaborators&.include?(user)
      
      user_shares = active_shares_for_user(user)
      user_shares.any? { |share| ['view', 'copy'].include?(share[:permission]) }
    end

    # Check if user has copy permission
    def user_can_copy?(user)
      return true if owner == user
      return true if folder&.collaborators&.include?(user)
      
      user_shares = active_shares_for_user(user)
      user_shares.any? { |share| share[:permission] == 'copy' }
    end

    # Add a new share
    def add_share(email, permission, expires_at)
      raise 'File is not shareable' unless shareable?
      raise 'Invalid permission' unless ['view', 'copy'].include?(permission)
      
      # Validate user exists
      target_user = Account.first(email: email)
      raise 'User not found' unless target_user
      raise 'Cannot share with owner' if target_user == owner
      
      # Check if user already has an active share
      existing_active = active_shares_for_user(target_user)
      if existing_active.any?
        raise "User already has active share with #{existing_active.first[:permission]} permission"
      end
      
      # Add new share info to cc_types
      share_info = "share:#{email}:#{permission}:#{expires_at.iso8601}"
      new_types = cc_types + [share_info]
      
      self.cc_types = new_types
      save_changes
      
      # Generate access token for the shared user
      generate_share_token(target_user, permission, expires_at)
    end

    # Remove share for specific user (mark as removed, don't delete)
    def remove_share(email)
      target_user = Account.first(email: email)
      raise 'User not found' unless target_user
      
      # Find and remove active shares for this user
      new_types = cc_types.reject do |type|
        if type.downcase.start_with?('share:')
          share = parse_share_entry(type)
          share && share[:email] == email && !share[:expired]
        else
          false
        end
      end
      
      # Add removal record
      removal_info = "share:#{email}:removed:#{Time.now.iso8601}"
      new_types << removal_info
      
      self.cc_types = new_types
      save_changes
    end

    # Update permission for existing share
    def update_share_permission(email, new_permission)
      raise 'Invalid permission' unless ['view', 'copy'].include?(new_permission)
      
      target_user = Account.first(email: email)
      raise 'User not found' unless target_user
      
      existing_shares = active_shares_for_user(target_user)
      raise 'No active share found for user' if existing_shares.empty?
      
      # Remove old share and add new one with updated permission
      old_share = existing_shares.first
      remove_share(email)
      add_share(email, new_permission, Time.parse(old_share[:expires_at]))
    end

    # Generate a limited scope token for file access
    def generate_share_token(user, permission, expires_at)
      payload = {
        type: 'shared_file_access',
        file_id: id,
        user_id: user.id,
        username: user.username,
        permission: permission,
        expires_file_share: expires_at.iso8601
      }
      
      # Create token that expires when share expires
      expiration_seconds = [(expires_at - Time.now).to_i, AuthToken::ONE_WEEK].min
      
      # Different scopes based on permission
      scope = case permission
              when 'view'
                AuthScope.new(AuthScope::READ_ONLY)
              when 'copy'
                AuthScope.new('files:read files:copy')
              else
                AuthScope.new(AuthScope::READ_ONLY)
              end
      
      AuthToken.create(
        payload,
        expiration_seconds,
        scope
      )
    end

    # Get comprehensive sharing information
    def sharing_info
      {
        has_shares: has_shares?,
        total_shares: share_entries.count,
        active_shares: active_shares.count,
        expired_shares: expired_shares.count,
        shares: share_entries.map do |share|
          {
            email: share[:email],
            username: Account.first(email: share[:email])&.username,
            permission: share[:permission],
            expires_at: share[:expires_at],
            expired: share[:expired],
            time_remaining: share[:expired] ? 'Expired' : time_remaining_description(share[:expires_at])
          }
        end
      }
    end

    def to_h
      base_attrs = {
        type: 'file',
        attributes: {
          id: id,
          filename: filename,
          description: description,
          content: content,
          cc_types: cc_types,
          shareable: shareable?,
          created_at: created_at,
          updated_at: updated_at
        },
        relationships: {
          folder: folder&.to_h,
          owner: owner&.to_json
        }
      }
      
      # Add sharing info if file has shares
      if has_shares?
        base_attrs[:sharing] = sharing_info
      end
      
      base_attrs
    end

    def to_json(options = {})
      JSON.generate(to_h, options)
    end

    def self.setup
      Dir.mkdir_p(UCCMe::STORE_DIR)
    end

    def self.locate
      FileUtils.mkdir_p(UCCMe::STORE_DIR)
    end

    # Find files shared with a specific user
    def self.shared_with_user(user)
      all.select do |file|
        file.shared_with?(user)
      end
    end

    # Get sharing statistics across all files
    def self.sharing_statistics
      total_files = count
      shareable_files = all.select(&:shareable?).count
      files_with_shares = all.select(&:has_shares?).count
      
      total_shares = all.sum { |f| f.share_entries.count }
      active_shares = all.sum { |f| f.active_shares.count }
      expired_shares = all.sum { |f| f.expired_shares.count }
      
      {
        total_files: total_files,
        shareable_files: shareable_files,
        files_with_shares: files_with_shares,
        total_shares: total_shares,
        active_shares: active_shares,
        expired_shares: expired_shares
      }
    end

    private

    # Parse share entry string: "share:email:permission:expiration"
    def parse_share_entry(share_str)
      parts = share_str.split(':')
      return nil unless parts.length >= 4 && parts[0].downcase == 'share'
      
      email = parts[1]
      permission = parts[2]
      expires_at_str = parts[3]
      
      begin
        expires_at = Time.parse(expires_at_str)
        expired = Time.now > expires_at
        
        {
          email: email,
          permission: permission,
          expires_at: expires_at_str,
          expired: expired,
          raw: share_str
        }
      rescue ArgumentError
        nil
      end
    end

    def time_remaining_description(expires_at_str)
      begin
        expires_at = Time.parse(expires_at_str)
        return 'Expired' if Time.now > expires_at
        
        seconds_remaining = (expires_at - Time.now).to_i
        
        if seconds_remaining < 3600 # Less than 1 hour
          minutes = seconds_remaining / 60
          "#{minutes} minutes"
        elsif seconds_remaining < 86400 # Less than 1 day  
          hours = seconds_remaining / 3600
          "#{hours} hours"
        else
          days = seconds_remaining / 86400
          "#{days} days"
        end
      rescue ArgumentError
        'Invalid expiration'
      end
    end
  end
end
