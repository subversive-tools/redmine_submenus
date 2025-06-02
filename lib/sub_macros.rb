# Required for Redmine plugin initialization
require 'redmine'

# Define a module to encapsulate the macro logic
module SubMacros
  # Register the macro with Redmine
  Redmine::WikiFormatting::Macros.register do
    # Description for the macro to explain its usage
    desc "Displays a list or table of subprojects. Options:

" +
         "{{subprojects}} -- default list view (only active subprojects at the top level are displayed)
" +
         "{{subprojects(view=table)}} -- table view (active subprojects at the top level with no roles displayed)
" +
         "{{subprojects(view=table, roles=Manager+Developer)}} -- table view with columns for specified roles (e.g., 'Manager' and 'Developer')
" +
         "{{subprojects(view=list, depth=2)}} -- nested list view showing up to 2 levels of active subprojects
" +
         "{{subprojects(view=table, depth=3, roles=all)}} -- table view showing all roles for subprojects up to 3 levels
"
    # Define the macro :subprojects
    macro :subprojects do |obj, args|
      # Ensure the macro is called within a project context
      return '' unless @project

      # Extract macro options: view (list/table), roles, and depth
      # Simplified args handling
      args, options = extract_macro_options(args, :view, :roles, :depth)
      view = options[:view].to_s.strip.downcase || 'list'
      # Display the selected view in the wiki as text
      # return "<p>args: #{args}</p>".html_safe

      # Extract and validate role names
      role_names = if options[:roles].present?
  if options[:roles].strip.downcase == 'all'
    Role.all.map(&:name) # All roles if 'roles=all'
  else
    options[:roles].to_s.split('+').map(&:strip) # Split roles by '+'
  end
else
  [] # No roles if 'roles' is not provided
end
roles = role_names.map { |role_name| Role.find_by_name(role_name) }.compact

      # Depth determines how many levels of subprojects to render
      # Default depth is 1, which limits rendering to only the top-level hierarchy
      depth = options[:depth].present? ? options[:depth].to_i : 1

      # Helper lambda to render a single table row for a project
      render_table_row = lambda do |project, level, roles|
        indent = level == 0 ? '' : "style='padding-left: #{level * 1.2}em;'"
        row = "<tr><td #{indent}>"
        row << "<span style='margin: 0 0.5em 0 -0.8em;'>&#8226;</span>" unless level == 0
        row << link_to(project.name, params[:controller] == 'wiki' ? project_wiki_path(project) : project_path(project))
        row << "</td>"
        roles.each do |role|
          members = project.members.select { |m| m.roles.include?(role) }
          member_names = members.map { |m| link_to(m.user.name, user_path(m.user)) }.join(', ')
          row << "<td>#{member_names}</td>"
        end
        row << "</tr>"
        row
      end

      # Render a table view of subprojects
      render_table_view = lambda do |project, roles, depth|
        output = "<table border='1'>
<tr><th>Subproject</th>"
        roles.each { |role| output << "<th>#{role.name}</th>" }
        output << "</tr>
"

        render_table = lambda do |p, c, d, level|
          ss = p.children.visible.to_a
          return unless ss.any?

          ss.each do |s|
            c << render_table_row.call(s, level, roles)
            render_table.call(s, c, d - 1, level + 1) if d > 1
          end
        end

        render_table.call(project, output, depth, 0)
        output << "</table>
"
        output
      end

      # Render a list view of subprojects
      render_list_view = lambda do |project, depth|
        render_list = lambda do |p, level|
          ss = p.children.visible.to_a
          return '' if ss.empty?

          html = "<ul>"
          ss.each do |s|
            html << "<li>" + link_to(s.name, params[:controller] == 'wiki' ? project_wiki_path(s) : project_path(s))
            html << render_list.call(s, level + 1) if depth > 1 && level + 1 < depth
            html << "</li>"
          end
          html << "</ul>"
          html
        end

        render_list.call(project, 0)
      end

      # Choose rendering based on the specified view
      html = case view
             when 'table'
               render_table_view.call(@project, roles, depth)
             else
               render_list_view.call(@project, depth)
             end

      # Return the generated HTML or an empty string if nil
      html.nil? ? '' : html.html_safe
    end

    # Define the macro :subpages
    desc "Displays a list or table of subpages of a wiki page. Options:

" +
         "{{subpages}} -- default list view (only subpages at the top level are displayed)
" +
         "{{subpages(view=table)}} -- table view (subpages at the top level)
" +
         "{{subpages(view=list, depth=2)}} -- nested list view showing up to 2 levels of subpages"

    macro :subpages do |obj, args|
      # Ensure the macro is called within a wiki context
      wiki_page = obj.is_a?(WikiPage) ? obj : obj.is_a?(WikiContent) ? obj.page : nil
      #return "<p>Invalid context: #{ERB::Util.html_escape(obj.inspect)}</p>".html_safe #unless wiki_page

      # Extract macro options: view (list/table) and depth
      args, options = extract_macro_options(args, :view, :depth)
      view = options[:view].to_s.strip.downcase || 'list'
      #return "<p>Options: #{ERB::Util.html_escape(options.inspect)}</p>".html_safe

      depth = options[:depth].present? ? options[:depth].to_i : 1

      # Helper lambda to render a single row for a page
      render_page_row = lambda do |page, level|
        indent = level == 0 ? '' : "style='padding-left: #{level * 1.2}em;'"
        "<tr><td #{indent}>#{level > 0 ? "<span style='margin: 0 0.5em 0 -0.8em;'>&#8226;</span>" : ""}#{link_to(page.title, project_wiki_page_path(page.project, page.title))}</td></tr>"
      end

      # Render a table view of subpages
      render_table_view = lambda do |page, depth|
        output = "<table border='1'>
<tr><th>Subpage</th></tr>
"

        render_table = lambda do |p, c, d, level|
          ss = WikiPage.where(parent_id: p.id)
          debug_info = "<p>Parent ID: \#{p.id}, Subpages Found: \#{ss.size}, Titles: \#{ss.map(&:title).join(', ')}</p>"
          debug_info.html_safe
          return unless ss.any?

          ss.each do |s|
            c << render_page_row.call(s, level)
            render_table.call(s, c, d - 1, level + 1) if d > 1
          end
        end

        render_table.call(page, output, depth, 0)
        output << "</table>
"
        output
      end

      # Render a list view of subpages
      render_list_view = lambda do |page, depth|
        render_list = lambda do |p, level|
          ss = WikiPage.where(parent_id: p.id)
          return '' if ss.empty?

          html = "<ul>"
          ss.each do |s|
            html << "<li>" + link_to(s.title, project_wiki_page_path(s.project, s.title))
            html << render_list.call(s, level + 1) if depth > 1 && level + 1 < depth
            html << "</li>"
          end
          html << "</ul>"
          html
        end

        render_list.call(page, 0)
      end

      # Choose rendering based on the specified view
      html = case view
             when 'table'
               render_table_view.call(obj, depth)
             else
               render_list_view.call(obj, depth)
             end

      # Return the generated HTML or an empty string if nil
      html.nil? ? '' : html.html_safe
    end
  end
end
