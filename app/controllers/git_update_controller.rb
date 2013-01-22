class GitUpdateController < ApplicationController
  unloadable

  before_filter :find_project
  
  def index
    project = @project
  end
  
  def find_project
    render_404 if params[:proj_name].nil?
        
    @project = Project.where(:name => params[:proj_name]).first
  end
end
