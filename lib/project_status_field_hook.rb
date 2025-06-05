class ProjectStatusFieldHook < Redmine::Hook::ViewListener
  def view_projects_form(context = {})
    project = context[:project]
    form = context[:form]
    
    # Find the Project Status custom field
    project_status_field = CustomField.where(
      type: 'ProjectCustomField',
      name: 'Project Status',
      field_format: 'list'
    ).first
    
    return '' unless project_status_field
    
    # Check if user has permission to manage project status
    unless User.current.allowed_to?(:manage_project_status, project)
      # Hide the Project Status field by adding CSS to hide it
      field_id = "project_custom_field_values_#{project_status_field.id}"
      return <<-HTML
        <script type="text/javascript">
          document.addEventListener('DOMContentLoaded', function() {
            var field = document.getElementById('#{field_id}');
            if (field) {
              var container = field.closest('p, div, .field, tr');
              if (container) {
                container.style.display = 'none';
              }
            }
            
            // Also hide the label
            var labels = document.querySelectorAll('label[for="#{field_id}"]');
            labels.forEach(function(label) {
              var container = label.closest('p, div, .field, tr');
              if (container) {
                container.style.display = 'none';
              }
            });
          });
        </script>
      HTML
    end
    
    return ''
  end
end
