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
    def self.call(auth:, file:) # rubocop:disable Lint/UnusedMethodArgument
      raise NotFoundError unless file

      # policy = FilePolicy.new(auth.account, file, auth.scope)
      # raise ForbiddenError unless policy.can_view?

      file
    end
  end
end
