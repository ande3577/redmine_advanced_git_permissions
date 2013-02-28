class RefRulesController < ApplicationController
  unloadable

  append_before_filter :clear_globals
  append_before_filter :find_optional_ref_rule
  append_before_filter :require_ref_rule, :only => [:show, :edit, :update, :destroy, :members, :add_members]  
  append_before_filter :find_repository
  append_before_filter :authorize, :except => [:index, :members, :delete_member]
  append_before_filter :find_ref_rules, :only => [:index]
  append_before_filter :find_members, :only => [:members, :add_members]
  append_before_filter :symbolize_default_rules, :only => [:update_repository_settings]
  
  def index
    if @project.nil?
      if !User.current().admin?
        deny_access
        return false
      end
    elsif !User.current.allowed_to?(:commit_access, @project) and !User.current.allowed_to?(:manage_ref_rules, @project) 
      deny_access
      return false
    end
    
    respond_to do |format|
          format.html
    end
  end

  def show
    respond_to do |format|
          format.html
    end
  end

  def new
    if @repository.nil?
      @ref_rule = RefRule.new(:global => true)
    else
      @ref_rule = RefRule.new(:repository => @repository)
    end

    respond_to do |format|
          format.html
    end
  end

  def create
    @ref_rule = RefRule.new(params[:ref_rule])
    @ref_rule.repository = @repository
    symbolize(@ref_rule)
    unless @ref_rule.save
      flash[:error] = l(:notice_git_create_failed)
    else
      flash[:notice] = l(:notice_git_create_succeeded) 
    end
    
    respond_to do |format|
      format.html { redirect_to :action => :index, :repository_id => @repository }
    end
    
  end

  def edit
    respond_to do |format|
          format.html
    end
  end

  def destroy
    begin
      if @ref_rule.reload.destroy()
        flash[:notice] = l(:notice_git_delete_succeeded)
      else
        flash[:error] = l(:notice_git_delete_failed)
      end
    rescue ::ActiveRecord::RecordNotFound # raised by #reload if issue no longer exists
      # nothing to do, issue was already deleted (eg. by a parent)
    end

    respond_to do |format|
          format.html { redirect_to :action => :index, :repository_id => @repository }
    end
  end

  def update
    @ref_rule.safe_attributes = params[:ref_rule]
    symbolize(@ref_rule)
    if !@ref_rule.repository_id_changed? and !@ref_rule.global_changed? and @ref_rule.save
      flash[:notice] = l(:notice_git_update_succeeded)
    else
      flash[:error] = l(:notice_git_update_failed)
      begin
        @ref_rule.reload
      rescue ::ActiveRecord::RecordNotFound # raised by #reload if issue no longer exists
      # nothing to do, issue was already deleted (eg. by a parent)
      end
    end
     
    respond_to do |format|
          format.html { redirect_to :action => :index, :repository_id => @repository }
    end
  end
  
  def evaluate
    if params[:value].nil? or params[:value].empty? or params[:expression].nil? or params[:expression].empty?
      @matches = false
    else
      @matches = RefRule.evaluate(params[:value],params[:expression], !params[:regex].nil? && params[:regex] != 'false')      
    end
    
    respond_to do |format|
        format.js { render :partial => 'evaluate', :locals => { :matches => @matches } }
        format.html { render :partial => 'evaluate', :locals => { :matches => @matches } }
    end
  end
  
  def update_repository_settings
    if @repository.nil?
      render_404
      return false
    end
    
    @repository.inherit_global_rules = params[:inherit_global_rules]
    @repository.default_branch_rule = @default_branch_rule
    @repository.default_tag_rule = @default_tag_rule
      
    if !@repository.save
      flash[:error] = l(:notice_git_update_failed)
      begin
        @repository.reload
      rescue ::ActiveRecord::RecordNotFound # raised by #reload if issue no longer exists
      # nothing to do, issue was already deleted (eg. by a parent)
      end
    end
    
    respond_to do |format|
      format.html { redirect_to :action => :index }
    end
  end
  
  def members
    if !User.current.allowed_to?(:commit_access, @project) and !User.current.allowed_to?(:manage_ref_rules, @project)
      deny_access
      return false
    end
    
    @available_members = []
    @project.users.each do |u|
      @available_members << u if has_commit_access?(u.id) and @ref_rule.ref_members.where(:user_id => u.id).empty?
    end
    
    respond_to do |format|
      format.html
    end
  end
  
  def add_members
    if !params[:user_ids].nil?
      params[:user_ids].each do |uid|
        if @members.where(:user_id => uid).empty?
          if !has_commit_access?(uid) or !RefMember.create(:user_id => uid, :ref_rule => @ref_rule).save
            flash[:error] = l(:notice_git_add_member_failed)
          end
        end
      end
    end
    
    @ref_rule.reload
    
    respond_to do |format|
      format.html { redirect_to :action => :members }
    end
  end
  
  def delete_member
    @member = RefMember.where(:id => params[:member_id]).first
    if @member.nil?
      render_404
      return false
    end
    
    @ref_rule = @member.ref_rule
    @repository = @ref_rule.repository
    @project = @repository.project
    
    unless User.current.allowed_to?(:manage_ref_rules, @project)
      deny_access
      return false
    end
    
    begin
      if @member.reload.destroy()
        flash[:notice] = l(:notice_git_member_delete_succeeded)
      else
        flash[:error] = l(:notice_git_member_delete_failed)
      end
    rescue ::ActiveRecord::RecordNotFound # raised by #reload if issue no longer exists
      # nothing to do, issue was already deleted (eg. by a parent)
    end
    
    respond_to do |format|
      format.html { redirect_to :action => :members, :id => @ref_rule.id }
    end    
  end
  
  private
  def clear_globals
    @repository = nil
    
    @project = nil
    @ref_rules = nil
    @ref_rule = nil
    @default_branch_rule = nil
    @default_tag_rule = nil
  end
  
  def find_optional_ref_rule
    unless params[:id].nil?
      @ref_rule = RefRule.where(:id => params[:id]).first
    end
  end
  
  def require_ref_rule
    if @ref_rule.nil?
      render_404
      return false
    end
  end
  
  def find_repository
    repository_id = params[:repository_id]
    if repository_id.nil? and !params[:ref_rule].nil?
      repository_id = params[:ref_rule][:repository_id]
    end
    
    if !@ref_rule.nil?
       @repository = @ref_rule.repository
       unless repository_id.nil?
         render_404
         return false
       end
    elsif !repository_id.nil?
      @repository = Repository.where(:id => repository_id).first
      if @repository.nil?
        render_404
        return false
      end
    end
    
    @project = @repository.project unless @repository.nil?
    
    true
  end
  
  def authorize
    if @repository.nil?
      if !User.current().admin?
        deny_access
        return false
      end
    elsif !User.current().allowed_to?({:controller => :ref_rules, :action => params[:action]}, @project, :global => false)
      deny_access
      return false
    end
    true
  end
  
  def find_ref_rules
    if @repository.nil?
      @ref_rules = RefRule.where(:global => true)
    else
      @ref_rules = @repository.ref_rules
    end
  end
  
  def find_members
    if @ref_rule.nil? or @ref_rule.global or @ref_rule.rule_type.to_sym != :private_ref
      render_404
      return false
    end

    @members = @ref_rule.ref_members
  end
  
  def symbolize_default_rules
    unless params[:default_branch_rule].nil?
      @default_branch_rule = params[:default_branch_rule].to_sym unless RefRule.rule_types.index(params[:default_branch_rule].to_sym).nil?
    end
    
    unless params[:default_tag_rule].nil?
      @default_tag_rule = params[:default_tag_rule].to_sym unless RefRule.rule_types.index(params[:default_tag_rule].to_sym).nil?
    end
    
  end
  
  def symbolize(ref_rule)
    ref_rule.rule_type = ref_rule.rule_type.to_sym unless ref_rule.rule_type.nil?
    ref_rule.ref_type = ref_rule.ref_type.to_sym unless ref_rule.rule_type.nil?
  end
  
  def has_commit_access?(principal_id)
    user = User.where(:id => principal_id).first; 
    unless user.nil?
      return user.allowed_to?(:commit_access, @project)
    end
    false
  end
  
end
