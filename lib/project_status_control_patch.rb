module ProjectStatusControlPatch
  def self.included(base)
    base.class_eval do
      # Alias method chain for update action
      alias_method :update_without_status_check, :update
      alias_method :update, :update_with_status_check
    end
  end

  def update_with_status_check
    # Check if Project Status custom field is being updated
    if params[:project] && params[:project][:custom_field_values]
      project_status_field = CustomField.where(
        type: 'ProjectCustomField',
        name: 'Project Status',
        field_format: 'list'
      ).first

      if project_status_field && params[:project][:custom_field_values].key?(project_status_field.id.to_s)
        # Check if user has permission to manage project status
        unless User.current.allowed_to?(:manage_project_status, @project)
          flash[:error] = l(:notice_not_authorized_to_change_project_status)
          redirect_to settings_project_path(@project)
          return
        end
      end
    end

    # Proceed with original update method
    update_without_status_check
  end
end

# Apply the patch to ProjectsController
unless ProjectsController.included_modules.include?(ProjectStatusControlPatch)
  ProjectsController.send(:include, ProjectStatusControlPatch)
end
