# frozen_string_literal: true

# Policy to determine if account can view a folder
class DocumentPolicy
  def initialize(account, document)
    @account = account
    @document = document
  end

  def can_view?
    account_owns_folder? || account_collaborates_on_folder?
  end

  def can_edit?
    account_owns_folder? || account_collaborates_on_folder?
  end

  def can_delete?
    account_owns_folder? || account_collaborates_on_folder?
  end

  def summary
    {
      can_view: can_view?,
      can_edit: can_edit?,
      can_delete: can_delete?
    }
  end

  private

  def account_owns_folder?
    @document.folder.owner == @account
  end

  def account_collaborates_on_folder?
    @document.folder.collaborators.include?(@account)
  end
end
