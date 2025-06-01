# frozen_string_literal: true

module UCCMe
  # Scope of folders an account can access
  class FolderPolicy
    # Scope of folder policies
    class AccountScope
      def initialize(current_account, target_account = nil)
        target_account ||= current_account
        @full_scope = all_folders(target_account)
        @current_account = current_account
        @target_account = target_account
      end

      def viewable
        if @current_account == @target_account
          @full_scope
        else
          @full_scope.select do |proj|
            includes_collaborator?(proj, @current_account)
          end
        end
      end

      private

      def all_folders(account)
        account.owned_folders + account.collaborations
      end

      def includes_collaborator?(folder, account)
        folder.collaborators.include? account
      end
    end
  end
end