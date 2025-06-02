require_dependency 'application_helper'

module SubMenuPatches
  module ApplicationHelperPatch
    def self.included(base)
      base.class_eval do
        def page_header_title
          if @project.nil? || @project.new_record?
            # Return the application title if there's no project or if the project is new
            h(Setting.app_title)
          else
            b = []
            # Retrieve visible ancestors of the project, excluding the root
            ancestors = (@project.root? ? [] : @project.ancestors.visible.to_a)
            
            if ancestors.any?
              # Handle root ancestor
              root = ancestors.shift
              b << link_to_project(root, {:jump => current_menu_item}, :class => 'root')
              
              if ancestors.size > 2
                b << "\xe2\x80\xa6" # Ellipsis for truncated ancestors
                ancestors = ancestors[-2, 2]
              end

              # Add links for remaining ancestors
              b += ancestors.collect do |p|
                link_to_project(p, {:jump => current_menu_item}, :class => 'ancestor')
              end
            end

            # Check if subprojects should be shown in a dropdown menu
            @uprojects = @project.children.visible
            if Setting.plugin_redmine_submenus['show_subprojects_menu'] && @uprojects.present?
              # Generate dropdown trigger
              sub1 = content_tag(:span, h(@project)+' '+Setting.plugin_redmine_submenus['dropdown_menu_symbol'], class: 'current-project drdn-trigger')
              
              # Generate dropdown content
              sub2 = content_tag(:div, class: 'drdn-content contextual', style: 'right: auto; top: auto; line-height: 1rem; padding: 0;') do
                content_tag(:div, class: 'drdn-items') do
                  # Map each subproject to a link element
                  @uprojects.map do |uproject|
                    link_to_project(uproject, {:jump => current_menu_item}, :style => 'font-size: 0.9rem; font-weight: initial; opacity: initial; color: initial;')
                  end.join.html_safe
                end
              end

              # Add the dropdown to the breadcrumb array
              b << content_tag(:span, sub1+sub2, class: 'drdn', style: 'position: inherit;')  # position:inherit -> to override overflow:hidden of header element
            else
              # If no subprojects, show the project name only
              b << content_tag(:span, h(@project), class: 'current-project')
            end

            if b.size > 1
              # Create a breadcrumb trail with separators if there are multiple elements
              separator = content_tag(:span, ' &raquo; '.html_safe, class: 'separator')
              path = safe_join(b[0..-2], separator) + separator
              b = [content_tag(:span, path.html_safe, class: 'breadcrumbs'), b[-1]]
            end

            # Safely join the breadcrumb elements
            safe_join b
          end
        end
      end
    end
  end
end

# Apply the monkey patch
ApplicationHelper.send(:include, SubMenuPatches::ApplicationHelperPatch)
