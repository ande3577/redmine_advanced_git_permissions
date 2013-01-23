class GitUpdateController < ApplicationController
  unloadable

  before_filter :find_project, :find_user
  
  def create_branch
    logger.debug "User.current = #{User.current.inspect}"
    logger.debug "@project = #{@project.inspect}"
    
    if params[:branch].nil?
      render_404
    elsif User.current.allowed_to?(:create_branch, @project)
      render_api_ok
    else
      render_403
    end
  end
  
  def find_project
    if params[:proj_name].nil?
      render_404
      return false
    end
        
    @project = Project.where(:name => params[:proj_name]).first
    if @project.nil?
      render_404 
      return false
    end
    true
  end
  
  def find_user
    if params[:user_name].nil?
      render_403
      return false
    end
    User.current = User.where(:login => params[:user_name]).first
    true
  end
end
