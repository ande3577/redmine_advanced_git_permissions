class GitUpdateController < ApplicationController
  unloadable

  skip_before_filter :check_if_login_required
  before_filter :find_project, :find_user
  
  append_before_filter :validate_branch, :only => [ :create_branch, :delete_branch, :update_branch ]
  append_before_filter :validate_tag, :only => [ :create_tag, :delete_tag, :update_tag ]
    
  def create_branch
    if User.current.allowed_to?(:create_branch, @project)
      render_api_ok
    else
      render_403
    end
  end
  
  def delete_branch
    if User.current.allowed_to?(:delete_branch, @project)
      render_api_ok
    else
      render_403
    end
  end
  
  def update_branch
    fast_forward = params[:ff]
    if fast_forward.nil?
      render_404
    elsif !User.current.allowed_to?(:commit_access, @project)
      render_403
    elsif !fast_forward and !User.current.allowed_to?(:non_ff_update, @project)
      render_403
    else
      render_api_ok
    end
      
  end
  
private 
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
  
  def validate_branch
    if params[:branch].nil? or !legal_branch(params[:branch])
       render_404
       return false
    elsif protected_branch(params[:branch]) and !User.current().allowed_to?(:update_protected_branch, @project)
      render_403
      return false
    end
    true
  end
  
  def validate_tag
    if params[:tag].nil? or !legal_branch(params[:tag])
       render_404
       return false
    elsif protected_tag(params[:tag]) and !User.current().allowed_to?(:update_protected_tag, @project)
      render_403
      return false
    end
    true
  end

  def legal_branch(branch)
    true
  end

  def protected_branch(branch)
    false
  end
  
  def legal_tag(tag)
    true
  end
  
  def protected_tag(tag)
    false
  end
  
end
