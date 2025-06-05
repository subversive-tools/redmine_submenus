module ProjectStatusViewPatch
  def self.included(base)
    base.class_eval do
      # Add a helper method to check if project status field should be shown
      def show_project_status_field?(project)
        User.current.allowed_to?(:manage_project_status, project)
      end
    end
  end
end

# Apply the patch to ApplicationHelper to make it available in all views
unless ApplicationHelper.included_modules.include?(ProjectStatusViewPatch)
  ApplicationHelper.send(:include, ProjectStatusViewPatch)
end
