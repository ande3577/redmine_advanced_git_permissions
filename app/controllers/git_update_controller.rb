class GitUpdateController < ApplicationController
  unloadable

  skip_before_filter :check_if_login_required
  before_filter :check_enabled, :find_project, :find_repository, :find_user, :check_for_disabled, :require_commit_access 
  
  append_before_filter :authorize, :except => :update_branch
  append_before_filter :validate_branch, :only => [ :create_branch, :delete_branch, :update_branch ]
  append_before_filter :validate_tag, :only => [ :create_tag, :delete_tag, :update_tag ]
  append_before_filter :require_annotated, :only => [:create_tag, :update_tag]
    
  def create_branch
    if @branch_type == :protected_ref and !User.current().allowed_to?(:create_protected_ref, @project)
      render_403 :message => l( :notice_git_user_not_authorized_create_protected_branch, :ref_name => params[:branch] )
      return false
    end    

    render_api_ok
  end
  
  def delete_branch
    if @branch_type == :protected_ref and !User.current().allowed_to?(:delete_protected_ref, @project)
      render_403 :message => l( :notice_git_user_not_authorized_delete_protected_branch, :ref_name => params[:branch] )
      return false
    end    
    
    render_api_ok
  end
  
  def update_branch
    if @branch_type == :protected_ref and !User.current().allowed_to?(:update_protected_ref, @project)
      render_403 :message => l( :notice_git_user_not_authorized_protected_branch, :ref_name => params[:branch] )
      return false
    end    
    
    fast_forward = params[:ff]
    if fast_forward.nil?
      render_404 :message => :notice_git_fastforward_not_specified
      return false
    elsif (fast_forward.empty? or fast_forward == "0")
      if !User.current.allowed_to?(:non_ff_update, @project)
        render_403 :message => l(:notice_git_fastforward_not_authorized, :ref_name => params[:branch])
        return false
      elsif @branch_type == :protected_ref and !User.current().allowed_to?(:non_ff_protected_update, @project)
        render_403 :message => l( :notice_git_user_not_authorized_non_ff_protected_branch, :ref_name => params[:branch] )
        return false 
      end
    end
    render_api_ok
  end
  
  def create_tag
    render_api_ok
  end
  
  def delete_tag
    render_api_ok
  end
  
  def update_tag
    render_api_ok
  end
  
private 
  def find_project
    if params[:proj_name].nil?
      render_404 :message => :notice_git_project_not_specified
      return false
    end
        
    @project = Project.where(:name => params[:proj_name]).first
    if @project.nil?
      render_404  :message => l(:notice_git_project_not_found, :project_id => params[:proj_name])
      return false
    end
    true
  end
  
  def find_user
    if params[:user_name].nil?
      render_403 :message => :notice_git_user_not_specified
      return false
    end
    User.current = User.where(:login => params[:user_name]).first
    true
  end
  
  def find_repository
    if params[:repository].nil?
      render_404 :message => :notice_git_repository_not_specified
      return false
    end
    
    @repository = @project.repositories.where(:url => params[:repository]).first
    
    if @repository.nil?
      render_404 :message => :notice_git_repository_not_found
      return false
    end
    true
  end
  
  def check_for_disabled
    # if advanced permissions disabled on the repository, just treat it as enabled
    unless @repository.enable_advanced_permissions
      render_api_ok
      return false
    end
    true
  end
  
  def require_commit_access
    if !User.current.allowed_to?(:commit_access, @project)
        render_403 :message => :notice_git_user_not_authorized_to_commit
        return false 
    end
  end
  
  def validate_branch
    if params[:branch].nil?
       render_404 :message => :notice_git_branch_not_specified
       return false
    end

    @branch_type = @repository.evaluate_ref :branch, params[:branch], User.current
    if @branch_type == :private_ref 
      if User.current().allowed_to?(:manage_private_ref, @project)
        @branch_type = :public_ref
      else
        render_403 :message => l( :notice_git_private_branch, :ref_name => params[:branch] )
        return false   
      end
    elsif @branch_type == :illegal_ref and (params[:action] != :delete_branch.to_s or !User.current().allowed_to?(:delete_illegal_ref, @project))
      render_403 :message => l( :notice_git_illegal_branch, :ref_name => params[:branch] )
      return false    
    end
    true
  end
  
  def validate_tag
    if params[:tag].nil?
       render_404 :message => :notice_git_tag_not_specified
       return false
    end

    logger.debug "params = #{params.inspect}"
           
    tag_type = @repository.evaluate_ref :tag, params[:tag], User.current
    if tag_type == :illegal_ref and (params[:action] != :delete_tag.to_s or !User.current().allowed_to?(:delete_illegal_ref, @project))
       render_403 :message => l( :notice_git_illegal_tag, :ref_name => params[:tag] )
       return false
    elsif tag_type == :protected_ref and !User.current().allowed_to?(:update_protected_ref, @project)
      render_403 :message => l( :notice_git_user_not_authorized_protected_tag, :ref_name => params[:tag] )
      return false
    end
    true
  end
  
  def require_annotated
    required = Setting.plugin_redmine_advanced_git_permissions[:require_annotated_tag] ? true : false
    
    if params[:annotated].nil?
      render_404 :message => :notice_git_annotated_not_specified
      return false
    elsif (params[:annotated].empty? or params[:annotated] == "0") and required 
      render_403 :message => l( :notice_git_unannotated_tag_not_allowed, :ref_name => params[:tag] )
      return false
    end
    true
  end

  def deny_access
    case params[:action]
    when "create_branch"
      message = l( :notice_git_cannot_create_branch, :ref_name => params[:branch] )
    when "delete_branch"
      message = l( :notice_git_cannot_delete_branch, :ref_name => params[:branch] )
    when "create_tag"
      message = l( :notice_git_cannot_create_tag, :ref_name => params[:tag] )
    when "delete_tag"
      message = l( :notice_git_cannot_delete_tag, :ref_name => params[:tag] )
    when "update_tag"
      message = l( :notice_git_cannot_update_tag, :ref_name => params[:tag] )
    end
    
    render_403 :message => message
  end
  
  def render_403(params)
    render_error :message => params[:message], :status => 403
  end
  
  def render_404(params)
      render_error :message => params[:message], :status => 404
  end
  
  def render_api_ok
    render :text => '', :status => :ok, :layout => nil
  end
  
  def render_error(params)
    @message = params[:message]
    @message = l(@message) if @message.is_a?(Symbol)
    render :text => @message, :status => params[:status], :layout => nil
  end
  
  def check_enabled
    User.current = nil
    unless Setting.sys_api_enabled? && params[:key].to_s == Setting.sys_api_key
      render :text => 'Access denied. Repository management WS is disabled or key is invalid.', :status => 403
      return false
    end
  end
  
end
