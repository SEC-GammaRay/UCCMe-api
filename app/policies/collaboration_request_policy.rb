# frozen_string_literal: true

module UCCMe
  # Policy to determine if an account can view a particular folder
  class CollaborationRequestPolicy
    def initialize(folder, requestor_account, target_account)
      @folder = folder
      @requestor_account = requestor_account
      @target_account = target_account
      @requestor = UCCMe::FolderPolicy.new(requestor_account, folder)
      @target = UCCMe::FolderPolicy.new(target_account, folder)
    end

    def can_invite?
      @requestor.can_add_collaborators? && @target.can_collaborate?
    end

    def can_remove?
      @requestor.can_remove_collaborators? && target_is_collaborator?
    end

    private

    def target_is_collaborator?
      @folder.collaborators.include?(@target_account)
    end
  end
end
