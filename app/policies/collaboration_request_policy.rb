# frozen_string_literal: true

module UCCMe
  # Policy to determine if an account can view a particular folder
  class CollaborationRequestPolicy
    def initialize(folder, requestor_account, target_account, auth_scope = nil)
      @folder = folder
      @requestor_account = requestor_account
      @target_account = target_account
      @auth_scope = auth_scope
      @requestor = FolderPolicy.new(requestor_account, folder, auth_scope)
      @target = FolderPolicy.new(target_account, folder, auth_scope)
    end

    def can_invite?
      can_write? &&
        @requestor.can_add_collaborators? && @target.can_collaborate?
    end

    def can_remove?
      can_write? &&
        @requestor.can_remove_collaborators? && target_is_collaborator?
    end

    private

    def can_write?
      @auth_scope ? @auth_scope.can_write?('folders') : false
    end

    def target_is_collaborator?
      @folder.collaborators.include?(@target_account)
    end
  end
end
