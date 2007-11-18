class RepositoriesController < ApplicationController
  before_filter :find_project, 
    :only => [:show, :new, :create, :edit, :update]
  
  private
    def find_project
      @project = Project.find_by_slug(params[:project_id])
      raise ActiveRecord::RecordNotFound unless @project
    end
end
