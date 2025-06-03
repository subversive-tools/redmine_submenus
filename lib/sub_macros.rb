# Required for Redmine plugin initialization
require 'redmine'

# Define a module to encapsulate the macro logic
module SubMacros
  # Register the macro with Redmine
  Redmine::WikiFormatting::Macros.register do
    # Description for the macro to explain its usage
    desc "Displays a list, table or kanban view of subprojects. Options:

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
" +
         "{{subprojects(view=kanban)}} -- kanban view with subprojects as cards grouped by status (requires 'Project Status' custom field)
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
        indent_class = level == 0 ? '' : "table-indent-#{level}"
        row = "<tr><td class='#{indent_class}'>"
        row << "<span class='table-bullet'>&#8226;</span>" unless level == 0
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

      # Render a kanban view of subprojects
      render_kanban_view = lambda do |project|
        # Find the Project Status custom field
        project_status_field = CustomField.where(
          type: 'ProjectCustomField', 
          name: 'Project Status',
          field_format: 'list'
        ).first

        # Check if custom field exists and is of correct type
        unless project_status_field
          return "<div class='kanban-warning'>
                    <strong>WARNING:</strong> Kanban view requires a custom field 'Project Status' of type 'List' for projects. 
                    This can be set up by an administrator under <em>Administration → Custom Fields → Projects</em>.
                  </div>".html_safe
        end

        # Get only active, visible subprojects
        active_subprojects = project.children.visible.where(status: Project::STATUS_ACTIVE)
        
        return "<p>No active subprojects found.</p>".html_safe if active_subprojects.empty?

        # Group projects by their Project Status custom field value
        kanban_groups = {}
        
        # Get the possible values from the custom field (in the correct order)
        status_options = project_status_field.possible_values
        
        # Initialize all status columns (even empty ones)
        status_options.each do |status|
          kanban_groups[status] = []
        end
        
        # Track projects without status separately
        projects_without_status = []
        
        # Group projects by their status
        active_subprojects.each do |subproject|
          status_value = subproject.custom_field_value(project_status_field)
          if status_value.present? && status_options.include?(status_value)
            kanban_groups[status_value] << subproject
          else
            projects_without_status << subproject
          end
        end

        # Generate Kanban HTML (CSS is loaded via assets pipeline)
        html = "<div class='kanban-board'>"
        
        # Render columns in the order: "Kein Status" (if exists) + defined status options
        columns_order = []
        
        # Add "No Status" column only if there are projects without status
        if projects_without_status.any?
          columns_order << "No Status"
          kanban_groups["No Status"] = projects_without_status
        end
        
        # Add all defined status columns
        columns_order += status_options
        
        columns_order.each do |status|
          projects_in_status = kanban_groups[status] || []
          
          # Parse meta-status from status name
          display_name = status
          meta_status_class = ""
          
          if status != "No Status" && status.match(/-([pid])$/)
            meta_suffix = $1
            display_name = status.gsub(/-[pid]$/, '') # Remove meta-status from display
            
            case meta_suffix
            when 'p'
              meta_status_class = " meta-pool"
            when 'i'
              meta_status_class = " meta-implementation"
            when 'd'
              meta_status_class = " meta-done"
            end
          end
          
          html << "<div class='kanban-column#{meta_status_class}'>"
          html << "<h3>#{ERB::Util.html_escape(display_name)}</h3>"
          html << "<div class='kanban-cards' data-status='#{ERB::Util.html_escape(status)}'>"
          
          projects_in_status.each do |subproject|
            html << "<div class='kanban-card' data-project-id='#{subproject.id}'>"
            html << "<div class='card-title'>"
            html << link_to(subproject.name, params[:controller] == 'wiki' ? project_wiki_path(subproject) : project_path(subproject))
            html << "</div>"
            
            if subproject.description.present?
              html << "<div class='card-description'>"
              html << ERB::Util.html_escape(truncate(subproject.description, length: 100))
              html << "</div>"
            end
            
            # Add project members if any
            if subproject.members.any?
              html << "<div class='card-members'>"
              html << "👥 " + subproject.members.limit(3).map { |m| m.user.name }.join(", ")
              html << (subproject.members.count > 3 ? " ..." : "")
              html << "</div>"
            end
            
            html << "</div>"
          end
          
          html << "</div>"
          html << "</div>"
        end
        
        html << "</div>"
        
        # Add JavaScript for drag and drop functionality
        html << "<script>
          document.addEventListener('DOMContentLoaded', function() {
            console.log('Kanban drag and drop initializing...');
            
            // Initialize drag and drop for kanban cards
            const cards = document.querySelectorAll('.kanban-card');
            const columns = document.querySelectorAll('.kanban-cards');
            
            console.log('Found cards:', cards.length, 'Found columns:', columns.length);
            
            let draggedElement = null;
            
            cards.forEach((card, index) => {
              console.log('Setting up card', index, card.dataset.projectId);
              
              card.draggable = true;
              
              card.addEventListener('dragstart', function(e) {
                console.log('Drag started for project:', this.dataset.projectId);
                draggedElement = this;
                e.dataTransfer.effectAllowed = 'move';
                e.dataTransfer.setData('text/html', this.outerHTML);
                e.dataTransfer.setData('text/plain', this.dataset.projectId);
                
                // Create a custom drag image with effects
                const dragImage = this.cloneNode(true);
                
                // Get original dimensions
                const originalRect = this.getBoundingClientRect();
                const originalStyles = window.getComputedStyle(this);
                
                // Apply original dimensions and styling to ensure exact copy
                dragImage.style.width = originalRect.width + 'px';
                dragImage.style.height = originalRect.height + 'px';
                dragImage.style.boxSizing = originalStyles.boxSizing;
                dragImage.style.padding = originalStyles.padding;
                dragImage.style.margin = originalStyles.margin;
                dragImage.style.border = originalStyles.border;
                
                // Apply the drag effects using CSS class
                dragImage.className += ' dragging';
                dragImage.style.position = 'absolute';
                dragImage.style.top = '-1000px'; // Move off-screen
                dragImage.style.pointerEvents = 'none';
                dragImage.style.zIndex = '9999';
                
                // Add to body temporarily
                document.body.appendChild(dragImage);
                
                // Set the custom drag image
                e.dataTransfer.setDragImage(dragImage, 125, 60); // Center it roughly
                
                // Clean up the drag image after a short delay
                setTimeout(() => {
                  if (document.body.contains(dragImage)) {
                    document.body.removeChild(dragImage);
                  }
                }, 100);
                
                // Make original card semi-transparent during drag
                this.classList.add('drag-placeholder');
              });
              
              card.addEventListener('dragend', function(e) {
                console.log('Drag ended');
                
                // Reset original card opacity
                this.classList.remove('drag-placeholder');
                draggedElement = null;
              });
            });
            
            columns.forEach((column, index) => {
              console.log('Setting up column', index, column.dataset.status);
              
              column.addEventListener('dragover', function(e) {
                e.preventDefault();
                e.stopPropagation();
                e.dataTransfer.dropEffect = 'move';
                this.classList.add('drag-over');
                return false;
              });
              
              column.addEventListener('dragenter', function(e) {
                e.preventDefault();
                e.stopPropagation();
                this.classList.add('drag-over');
                return false;
              });
              
              column.addEventListener('dragleave', function(e) {
                e.stopPropagation();
                // Only reset if we're really leaving the column
                if (!this.contains(e.relatedTarget)) {
                  this.classList.remove('drag-over');
                }
              });
              
              column.addEventListener('drop', function(e) {
                e.preventDefault();
                e.stopPropagation();
                
                console.log('Drop event triggered on column:', this.dataset.status);
                this.classList.remove('drag-over');
                
                if (draggedElement) {
                  const projectId = draggedElement.dataset.projectId;
                  const newStatus = this.dataset.status;
                  const originalParent = draggedElement.parentNode;
                  
                  console.log('Moving project', projectId, 'from', originalParent.dataset.status, 'to status', newStatus);
                  
                  // Only move if it's a different column
                  if (originalParent !== this) {
                    // Move the element to the end of the target column
                    this.appendChild(draggedElement);
                    
                    // Update project status via AJAX
                    updateProjectStatus(projectId, newStatus, draggedElement, originalParent);
                  }
                }
                
                return false;
              });
            });
            
            function updateProjectStatus(projectId, newStatus, cardElement, originalParent) {
              console.log('Updating project status:', projectId, 'to', newStatus);
              
              // Get CSRF token
              const csrfToken = document.querySelector('meta[name=\"csrf-token\"]');
              const token = csrfToken ? csrfToken.getAttribute('content') : '';
              
              fetch('/kanban_projects/' + projectId + '/update_status', {
                method: 'POST',
                headers: {
                  'Content-Type': 'application/json',
                  'X-CSRF-Token': token
                },
                body: JSON.stringify({
                  status: newStatus
                })
              })
              .then(response => {
                console.log('Response status:', response.status);
                return response.json();
              })
              .then(data => {
                console.log('Server response:', data);
                if (data.success) {
                  console.log('Status updated successfully');
                  // Optional: Show success feedback
                } else {
                  console.error('Server error:', data.error);
                  // Revert the move on error
                  if (originalParent && cardElement) {
                    originalParent.appendChild(cardElement);
                  }
                  alert('Error updating status: ' + data.error);
                }
              })
              .catch(error => {
                console.error('Network error:', error);
                // Revert the move on error
                if (originalParent && cardElement) {
                  originalParent.appendChild(cardElement);
                }
                alert('Network error updating status');
              });
            }
          });
        </script>"
        
        html
      end

      # Choose rendering based on the specified view
      html = case view
             when 'table'
               render_table_view.call(@project, roles, depth)
             when 'kanban'
               render_kanban_view.call(@project)
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
        indent_class = level == 0 ? '' : "table-indent-#{level}"
        "<tr><td class='#{indent_class}'>#{level > 0 ? "<span class='table-bullet'>&#8226;</span>" : ""}#{link_to(page.title, project_wiki_page_path(page.project, page.title))}</td></tr>"
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
