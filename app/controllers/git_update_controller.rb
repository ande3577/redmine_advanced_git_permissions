class GitUpdateController < ApplicationController
  unloadable

  before_filter :find_project, :find_user
  
  def index
    project = @project
  end
  
  def find_project
    render_404 if params[:proj_name].nil?
        
    @project = Project.where(:name => params[:proj_name]).first
    render_404 if @project.nil?
  end
  
  def find_user
    render_403 if params[:user_name].nil?
    @user = User.wheare(:name => params[:user_name]).first
    render_403 if @user.nil?
  end
end
