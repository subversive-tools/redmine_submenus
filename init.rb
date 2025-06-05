# Plugin submenus
require 'redmine'

Redmine::Plugin.register :redmine_submenus do
  name 'Submenus'
  author 'Stefan Mischke'
  description 'Adds dropdown menus to project titles and wiki titles and provides wiki macros, to easily navigate to sub projects or sub pages. Quasi the counterpart to the breadcrumb trail'
  version '0.2.1'
  url 'https://github.com/modoq/redmine_submenus'
  author_url 'https://github.com/modoq'

  # Plugin settings
  settings default: {
    'show_subprojects_menu' => '1',
    'show_subwiki_menu' => '1',
    'dropdown_menu_symbol' => '»'
  }, partial: 'settings/sub_settings'

  # Register permission for kanban project status updates under the existing project module
  permission :manage_project_status, { kanban_projects: [:update_status] }, require: :member

  # CSS loading handled via view hooks - no asset pipeline registration needed
  
  # Load patches
  Rails.configuration.to_prepare do
    require_dependency 'sub_menu_patches'
    require_dependency 'wiki_content_hook'
    require_dependency 'new_subproject_patch'
    require_dependency 'sub_macros'
    # require_dependency 'projects_helper_patch'
    require_dependency 'project_status_tag_hook'  # Re-enabled for fallback test
    require_dependency 'project_status_control_patch'  # Patch to control Project Status field access
    require_dependency 'project_status_view_patch'  # Patch to hide Project Status field if no permission
    require_dependency 'project_status_field_hook'  # View hook to hide Project Status field
  end
end
