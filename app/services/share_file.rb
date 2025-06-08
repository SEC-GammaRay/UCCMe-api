# frozen_string_literal: true

require 'securerandom'

module UCCMe
  class ShareFile
    class ForbiddenError < StandardError
      def message
        'You are not allowed to share this file'
      end
    end

    class NotFoundError < StandardError
      def message
        'File or user not found'
      end
    end

    # Refactored: Reduce parameter count by using a data object
    def self.call(params)
      new(params).execute
    end

    def initialize(params)
      @account = params[:account]
      @file_id = params[:file_id]
      @share_with_email = params[:share_with_email]
      @permissions = params[:permissions]
      @expires_at = params[:expires_at]
      @auth_scope = params[:auth_scope] || AuthScope.new(AuthScope::EVERYTHING)
    end

    def execute
      validate_resources
      validate_permissions
      validate_sharing_rules

      create_or_update_share
    end

    private

    attr_reader :account, :file_id, :share_with_email, :permissions, :expires_at, :auth_scope

    def validate_resources
      raise NotFoundError unless file && share_with_user
    end

    def validate_permissions
      policy = FilePolicy.new(account, file, auth_scope)
      raise ForbiddenError unless policy.can_share?
    end

    def validate_sharing_rules
      raise ForbiddenError if sharing_with_self?
    end

    def create_or_update_share
      if existing_share
        update_existing_share
      else
        create_new_share
      end
    end

    def file
      @file ||= StoredFile.first(id: file_id)
    end

    def share_with_user
      @share_with_user ||= Account.first(email: share_with_email)
    end

    def sharing_with_self?
      account == share_with_user
    end

    def existing_share
      @existing_share ||= FileShare.where(
        stored_file_id: file.id,
        shared_with_id: share_with_user.id
      ).first
    end

    def update_existing_share
      existing_share.update(
        permissions: JSON.generate(permissions),
        expires_at: expires_at
      )
      existing_share
    end

    def create_new_share
      FileShare.create(
        stored_file_id: file.id,
        owner_id: account.id,
        shared_with_id: share_with_user.id,
        permissions: JSON.generate(permissions),
        expires_at: expires_at,
        share_token: generate_share_token
      )
    end

    def generate_share_token
      SecureRandom.urlsafe_base64(32)
    end
  end
end
