# Plugin submenus
require 'redmine'

Redmine::Plugin.register :redmine_submenus do
  name 'Submenus'
  author 'Stefan Mischke'
  description 'Adds dropdown menus to project titles and wiki titles and provides wiki macros, to easily navigate to sub projects or sub pages. Quasi the counterpart to the breadcrumb trail'
  version '0.2.0'
  url 'https://github.com/modoq/redmine_submenus'
  author_url 'https://github.com/modoq'

  # Plugin settings
  settings default: {
    'show_subprojects_menu' => '1',
    'show_subwiki_menu' => '1',
    'dropdown_menu_symbol' => '»'
  }, partial: 'settings/sub_settings'

  # Load patches
  Rails.configuration.to_prepare do
    require_dependency 'sub_menu_patches'
    require_dependency 'wiki_content_hook'
    require_dependency 'new_subproject_patch'
    require_dependency 'sub_macros'
  end
end
