class ApiPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve(permission = "backend_manage")
      if(user.superuser?)
        scope.all
      else
        api_scopes = []
        if(permission == :any)
          api_scopes = user.api_scopes
        else
          api_scopes = user.api_scopes_with_permission(permission)
        end

        query_scopes = []
        api_scopes.each do |api_scope|
          query_scopes << {
            :frontend_host => api_scope.host,
            :"url_matches.frontend_prefix" => api_scope.path_prefix_matcher,
          }
        end

        scope.or(query_scopes)
      end
    end
  end

  def show?(permission = "backend_manage")
    can?("backend_manage")
  end

  def update?
    allowed = show?
    if(allowed && record.roles.present?)
      allowed = record.roles.all? do |role|
        ApiUserRolePolicy.new(user, role).show?
      end
    end

    allowed
  end

  def create?
    update?
  end

  def destroy?
    show?
  end

  def publish?
    can?("backend_publish")
  end

  def set_user_role?
    can?(:any)
  end

  private

  def can?(permission)
    allowed = false
    if(user.superuser?)
      allowed = true
    else
      api_scopes = []
      if(permission == :any)
        api_scopes = user.api_scopes
      else
        api_scopes = user.api_scopes_with_permission(permission)
      end

      api_scopes.each do |api_scope|
        if(record.frontend_host == api_scope.host)
          allowed = record.url_matches.all? do |url_match|
            api_scope.path_prefix_matcher.match(url_match.frontend_prefix)
          end
        end

        break if(allowed)
      end
    end

    allowed
  end
end
