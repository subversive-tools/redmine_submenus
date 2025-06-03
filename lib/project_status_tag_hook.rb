class ProjectStatusTagHook < Redmine::Hook::ViewListener
  # Load CSS for all plugin functionality
  def view_layouts_base_html_head(context = {})
    # Try different methods for cross-version compatibility
    begin
      stylesheet_link_tag 'kanban.css', plugin: 'redmine_submenus'
    rescue => e
      # Fallback: inline CSS loading if plugin assets don't work
      css_path = File.join(File.dirname(__FILE__), '..', 'assets', 'stylesheets', 'kanban.css')
      if File.exist?(css_path)
        css_content = File.read(css_path)
        "<style type='text/css'>#{css_content}</style>".html_safe
      else
        ""
      end
    end
  end

  def view_projects_show_left(context = {})
    project = context[:project]
    return "" unless project
    
    status_value = get_project_status_value(project)
    return "" unless status_value.present?
    
    display_name = parse_display_name(status_value)
    meta_class = parse_meta_class(status_value)
    
    render_status_tag_script(display_name, meta_class)
  end

  private

  def get_project_status_value(project)
    # Cache the CustomField lookup to avoid repeated queries
    @@project_status_field ||= CustomField.where(
      type: 'ProjectCustomField', 
      name: 'Project Status', 
      field_format: 'list'
    ).first
    
    return nil unless @@project_status_field
    project.custom_field_value(@@project_status_field)
  end

  def parse_display_name(status_value)
    status_value.gsub(/-[pid]$/, '')
  end

  def parse_meta_class(status_value)
    case status_value
    when /-p$/
      'meta-pool'
    when /-i$/
      'meta-implementation'
    when /-d$/
      'meta-done'
    else
      ''
    end
  end

  def render_status_tag_script(display_name, meta_class)
    # CSS is automatically loaded via assets/stylesheets/kanban.css
    # Only inject JavaScript for DOM manipulation
    <<~HTML
      <script>
        (function() {
          // Remove any existing status tags to avoid duplicates
          const existingTags = document.querySelectorAll('.project-status-tag');
          existingTags.forEach(tag => tag.remove());
          
          function addStatusTag() {
            const h2Element = document.querySelector('#content h2');
            if (h2Element && !h2Element.querySelector('.project-status-tag')) {
              const statusTag = document.createElement('span');
              statusTag.className = 'project-status-tag #{meta_class}';
              statusTag.textContent = '#{display_name.gsub("'", "\\'")}';
              h2Element.appendChild(statusTag);
              
              // Hide original custom field
              hideCustomField();
            }
          }
          
          function hideCustomField() {
            const items = document.querySelectorAll('li.list_cf span.label');
            items.forEach(function(label) {
              if (label.textContent.trim() === 'Project Status:') {
                label.closest('li').style.display = 'none';
              }
            });
          }
          
          // Execute immediately or wait for DOM
          if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', addStatusTag);
          } else {
            addStatusTag();
          }
        })();
      </script>
    HTML
  end
end