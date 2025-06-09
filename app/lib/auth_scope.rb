# frozen_string_literal: true


# Scopes for AuthTokens - handles authorization permissions
class AuthScope
  ALL = '*'
  VIEW = 'view'
  COPY = 'copy'

  EVERYTHING = '*:copy' # share includes read permissions
  VIEW_ONLY = '*:view'

  SEPARATOR = ' '
  DIVIDER = ':'

  def initialize(scopes = EVERYTHING)
    @scopes_str = scopes.to_s # Ensure it's a string
    @scopes = {}
    @scopes_str.split(SEPARATOR).each { |scope| add_scope(scope) }
  end

  def can_view?(resource)
    viewable?(ALL) || viewable?(resource)
  end

  def can_copy?(resource)
    copyable?(ALL) || copyable?(resource)

  end

  def to_s
    @scopes_str
  end

  private


  def viewable?(resource)
    copyable?(resource) || permission_granted?(resource, VIEW)
  end

  def copyable?(resource)
    permission_granted?(resource, COPY)

  end

  def permission_granted?(resource, permission)
    @scopes[resource]&.include?(permission) || false
  end

  def add_scope(scope)
    resource, permission = scope.split(DIVIDER)
    @scopes[resource] ||= []
    @scopes[resource] << permission
  end
end
