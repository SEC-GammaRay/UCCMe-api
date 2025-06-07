# frozen_string_literal: true

# Scopes for AuthTokens - handles authorization permissions
class AuthScope
  ALL = '*'
  READ = 'read'
  SHARE = 'share'
  
  EVERYTHING = '*:share'  # share includes read permissions
  READ_ONLY = '*:read'
  
  SEPARATOR = ' '
  DIVIDER = ':'

  def initialize(scopes = EVERYTHING)
    @scopes_str = scopes
    @scopes = {}
    scopes.split(SEPARATOR).each { |scope| add_scope(scope) }
  end

  def can_read?(resource)
    readable?(ALL) || readable?(resource)
  end

  def can_share?(resource)
    shareable?(ALL) || shareable?(resource)
  end

  def to_s
    @scopes_str
  end

  private

  def readable?(resource)
    shareable?(resource) || permission_granted?(resource, READ)
  end

  def shareable?(resource)
    permission_granted?(resource, SHARE)
  end

  def permission_granted?(resource, permission)
    @scopes[resource]&.include?(permission) ? true : false
  end

  def add_scope(scope)
    resource, permission = scope.split(DIVIDER)
    @scopes[resource] ||= []
    @scopes[resource] << permission
  end
end
