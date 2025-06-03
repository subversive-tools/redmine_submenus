RedmineApp::Application.routes.draw do
  post '/kanban_projects/:id/update_status', to: 'kanban_projects#update_status'
end
