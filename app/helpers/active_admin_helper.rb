module ActiveAdminHelper

  # make this method public (compulsory)
  def self.included(dsl)
    # nothing ...
  end

  def is_menu_authorized?(allowed_roles, disallowed_roles = [])
    if allowed_roles.blank? and disallowed_roles.blank?
      return true
    end
    allowed_roles.each do |allowed_role|
      if Role.where(name: allowed_role).first.id == current_admin_user.role_id
        return is_menu_not_authorized(disallowed_roles) & true
      end
      allowed_role_ancestry = Role.where(name: allowed_role).first.ancestor_ids
      if allowed_role_ancestry.include?(current_admin_user.role_id)
        return is_menu_not_authorized(disallowed_roles) & true
      end
    end
    return false
  end

  def is_resource_authorized?(allowed_roles, disallowed_roles = [])
    if !is_logged_in_user_active
      redirect_to destroy_admin_user_session_path
    end
    if !is_resource_authorized_boolean(allowed_roles, disallowed_roles)
      redirect_to admin_error_path, flash: {error: 'You are not allowed access to the requested resource.'}
    end
    return true
  end

  private

  def is_menu_not_authorized(disallowed_roles)
    if disallowed_roles.blank?
      return true
    end
    disallowed_roles.each do |disallowed_role|
      if Role.where(name: disallowed_role).first.id == current_admin_user.role_id
        return false
      end
    end
    return true
  end

  def is_resource_authorized_boolean(allowed_roles, disallowed_roles)
    if allowed_roles.blank? and disallowed_roles.blank?
      return true
    end
    allowed_roles.each do |allowed_role|
      if Role.where(name: allowed_role).first.id == current_admin_user.role_id
        return is_resource_not_authorized_boolean(disallowed_roles) & true
      end
      allowed_role_ancestry = Role.where(name: allowed_role).first.ancestor_ids
      if allowed_role_ancestry.include?(current_admin_user.role_id)
        return is_resource_not_authorized_boolean(disallowed_roles) & true
      end
    end
    return false
  end

  def is_resource_not_authorized_boolean(disallowed_roles)
    if disallowed_roles.blank?
      return true
    end
    disallowed_roles.each do |disallowed_role|
      if Role.where(name: disallowed_role).first.id == current_admin_user.role_id
        return false
      end
    end
    return true
  end

  def is_logged_in_user_active
    if AdminUser.find(current_admin_user.id).active
      return true
    else
      return false
    end
  end
end