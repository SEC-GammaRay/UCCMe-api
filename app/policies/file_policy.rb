# frozen_string_literal: true


# Policy to determine if account can view a file
class FilePolicy
  def initialize(account, file, auth_scope = AuthScope.new)
    @account = account
    @file = file
    @auth_scope = auth_scope
  end

  def can_view?
    (account_owns_file? || account_is_folder_collaborator? || has_active_share?) &&
      @auth_scope.can_view?('file')
  end

  def can_edit?
    (account_owns_file? || account_is_folder_collaborator?) &&
      @auth_scope.can_copy?('file')
  end

  def can_delete?
    account_owns_file? && @auth_scope.can_copy?('file')
  end

  def can_share?
    account_owns_file? && @auth_scope.can_copy?('file')
  end

  def can_copy?
    return false unless can_view?

    # Check if user has copy permission through share
    if has_active_share?
      share = active_share
      return share.can_copy?
    end

    # Owners and collaborators can always copy
    account_owns_file? || account_is_folder_collaborator?

  end

  def summary
    {
      can_view: can_view?,
      can_edit: can_edit?,
      can_delete: can_delete?,
      can_share: can_share?,
      can_copy: can_copy?
    }
  end

  private

  def account_owns_file?
    @file.owner == @account
  end

  def account_is_folder_collaborator?
    @file.folder&.collaborators&.include?(@account)
  end

  def has_active_share?
    !active_share.nil?
  end

  def active_share
    @active_share ||= UCCMe::FileShare.where(
      stored_file_id: @file.id,
      shared_with_id: @account.id
    ).where do
      # Handle both cases: no expiration (nil) or future expiration
      Sequel.expr(expires_at: nil) | (expires_at > Time.now)
    end.first

  end
end
