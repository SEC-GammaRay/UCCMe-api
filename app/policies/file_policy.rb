# frozen_string_literal: true

# Policy to determine if account can view a folder
class FilePolicy
  def initialize(account, file, auth_scope = nil)
    @account = account
    @file = file
    @auth_scope = auth_scope
  end

  def can_view?
    can_read? && (account_owns_folder? || account_collaborates_on_folder?)
  end

  def can_edit?
    can_write? && (account_owns_folder? || account_collaborates_on_folder?)
  end

  def can_delete?
    can_write? && (account_owns_folder? || account_collaborates_on_folder?)
  end

  def summary
    {
      can_view: can_view?,
      can_edit: can_edit?,
      can_delete: can_delete?
    }
  end

  private

  def can_read?
    @auth_scope ? @auth_scope.can_read?('files') : false
  end

  def can_write?
    @auth_scope ? @auth_scope.can_write?('file') : false
  end

  def account_owns_folder?
    @file.folder.owner == @account
  end

  def account_collaborates_on_folder?
    @file.folder.collaborators.include?(@account)
  end
end
