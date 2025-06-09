# frozen_string_literal: true

module UCCMe
  # Service to retrieve a file
  class GetFileQuery
    # Error for unauthorized access
    class ForbiddenError < StandardError
      def message
        'You are not allowed to access that file'
      end
    end

    # Error for cannot find a file
    class NotFoundError < StandardError
      def message
        'We could not find that file'
      end
    end

    # File for given requestor account

    def self.call(auth:, file:, account:)
      raise NotFoundError unless file

      # Extract auth_scope from auth token
      auth_scope = AuthScope.new(auth.scope)

      policy = FilePolicy.new(account, file, auth_scope)
      raise ForbiddenError unless policy.can_view?

      # Return file data with permissions info
      file_data = file.to_h
      file_data[:policies] = policy.summary
      file_data
    end
  end
end
