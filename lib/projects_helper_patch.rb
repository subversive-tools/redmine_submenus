# Patch to add project status tag to project overview
module ProjectsHelperPatch
  def self.included(base)
    base.class_eval do
      
      # Main method to render project status tag
      def project_status_tag(project)
        return "" unless project
        
        status_value = project_status_value(project)
        return "" unless status_value.present?
        
        render 'projects/status_tag', 
               status_value: status_value,
               display_name: parse_status_display_name(status_value),
               meta_class: parse_status_meta_class(status_value)
      end
      
      private
      
      # Get the status value from custom field
      def project_status_value(project)
        project_status_field = CustomField.where(
          type: 'ProjectCustomField', 
          name: 'Project Status',
          field_format: 'list'
        ).first
        
        return nil unless project_status_field
        project.custom_field_value(project_status_field)
      end      
      # Parse display name (remove meta-status suffix)
      def parse_status_display_name(status_value)
        status_value.gsub(/-[pid]$/, '')
      end
      
      # Parse meta-status class
      def parse_status_meta_class(status_value)
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
    end
  end
end

# Apply the patch
unless ProjectsHelper.included_modules.include?(ProjectsHelperPatch)
  ProjectsHelper.send(:include, ProjectsHelperPatch)
end