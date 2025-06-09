# frozen_string_literal: true

module UCCMe
  # Policy to determine if an account can view a particular folder
  class FolderPolicy
    def initialize(account, folder, auth_scope = nil)
      @account = account
      @folder = folder
      @auth_scope = auth_scope
    end

    def can_view?
      can_read? && (account_is_owner? || account_is_collaborator?)
    end

    # duplication is ok!
    def can_edit?
      can_write? && (account_is_owner? || account_is_collaborator?)
    end

    def can_delete?
      can_write? && account_is_owner?
    end

    def can_leave?
      account_is_collaborator?
    end

    def can_add_files?
      account_is_owner? || account_is_collaborator?
    end

    def can_remove_files?
      account_is_owner? || account_is_collaborator?
    end

    def can_add_collaborators?
      can_write? && account_is_owner?
    end

    def can_remove_collaborators?
      can_write? && account_is_owner?
    end

    def can_collaborate?
      !(account_is_owner? or account_is_collaborator?)
    end

    def summary # rubocop:disable Metrics/MethodLength
      {
        can_view: can_view?,
        can_edit: can_edit?,
        can_delete: can_delete?,
        can_leave: can_leave?,
        can_add_files: can_add_files?,
        can_delete_files: can_remove_files?,
        can_add_collaborators: can_add_collaborators?,
        can_remove_collaborators: can_remove_collaborators?,
        can_collaborate: can_collaborate?
      }
    end

    private

    def can_read?
      @auth_scope ? @auth_scope.can_read?('folders') : false
    end

    def can_write?
      @auth_scope ? @auth_scope.can_write?('folders') : false
    end

    def account_is_owner?
      @folder.owner == @account
    end

    def account_is_collaborator?
      @folder.collaborators.include?(@account)
    end
  end
end
