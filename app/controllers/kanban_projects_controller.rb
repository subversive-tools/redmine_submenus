class KanbanProjectsController < ApplicationController
  before_action :require_login
  before_action :find_project
  before_action :authorize_kanban_update

  def update_status
    project_status_field = CustomField.where(
      type: 'ProjectCustomField', 
      name: 'Project Status',
      field_format: 'list'
    ).first

    unless project_status_field
      render json: { success: false, error: 'Project Status custom field not found' }
      return
    end

    new_status = params[:status]
    
    # Validate that the status is one of the allowed values (or "No Status")
    allowed_statuses = project_status_field.possible_values + ["No Status"]
    unless allowed_statuses.include?(new_status)
      render json: { success: false, error: 'Invalid status value' }
      return
    end

    # Update the project's custom field value
    # For "No Status", we set it to nil/empty
    status_value = (new_status == "No Status") ? "" : new_status
    
    begin
      @project.custom_field_values = { project_status_field.id => status_value }
      
      if @project.save
        render json: { success: true, message: 'Project status updated successfully' }
      else
        render json: { success: false, error: @project.errors.full_messages.join(', ') }
      end
    rescue => e
      render json: { success: false, error: e.message }
    end
  end

  private

  def find_project
    @project = Project.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { success: false, error: 'Project not found' }
  end

  def authorize_kanban_update
    # Use Redmine's built-in authorization system
    unless User.current.allowed_to?(:manage_project_status, @project)
      render json: { success: false, error: 'Insufficient permissions to change project status' }
    end
  end
end
