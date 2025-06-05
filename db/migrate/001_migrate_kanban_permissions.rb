class MigrateKanbanPermissions < ActiveRecord::Migration[6.1]
  def up
    # Get existing kanban_allowed_roles setting
    plugin_settings = Setting.plugin_redmine_submenus || {}
    allowed_roles_setting = plugin_settings['kanban_allowed_roles']
    
    if allowed_roles_setting.present?
      # Parse the comma-separated role names
      allowed_role_names = allowed_roles_setting.split(',').map(&:strip)
      
      # Find these roles and grant them the new permission
      allowed_role_names.each do |role_name|
        role = Role.find_by(name: role_name)
        if role
          # Add the new permission to existing roles that had kanban access
          permissions = role.permissions || []
          unless permissions.include?(:manage_project_status)
            role.add_permission!(:manage_project_status)
            puts "Added 'manage_project_status' permission to role: #{role_name}"
          end
        else
          puts "Warning: Role '#{role_name}' not found - skipping"
        end
      end
    else
      # If no specific setting was found, grant permission to Manager role by default
      manager_role = Role.find_by(name: 'Manager')
      if manager_role
        permissions = manager_role.permissions || []
        unless permissions.include?(:manage_project_status)
          manager_role.add_permission!(:manage_project_status)
          puts "Added 'manage_project_status' permission to default Manager role"
        end
      end
    end
    
    # Remove the old setting from plugin settings
    if plugin_settings.key?('kanban_allowed_roles')
      plugin_settings.delete('kanban_allowed_roles')
      Setting.plugin_redmine_submenus = plugin_settings
      puts "Removed deprecated 'kanban_allowed_roles' from plugin settings"
    end
  end

  def down
    # Remove the permission from all roles
    Role.all.each do |role|
      if role.permissions&.include?(:manage_project_status)
        role.remove_permission!(:manage_project_status)
        puts "Removed 'manage_project_status' permission from role: #{role.name}"
      end
    end
    
    # Restore the old plugin setting (set to default)
    plugin_settings = Setting.plugin_redmine_submenus || {}
    plugin_settings['kanban_allowed_roles'] = 'Manager'
    Setting.plugin_redmine_submenus = plugin_settings
    puts "Restored 'kanban_allowed_roles' plugin setting"
  end
end
