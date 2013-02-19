class RefRulesController < ApplicationController
  unloadable

  append_before_filter :clear_globals
  append_before_filter :find_optional_ref_rule
  append_before_filter :require_ref_rule, :only => [:show, :edit, :update, :destroy]  
  append_before_filter :find_repository, :authorize
  append_before_filter :find_ref_rules, :only => [:index]
  
  def index
    if !@repository.nil?
      @ref_rules = @repository.ref_rules
    else
      @ref_rules = RefRule.where(:global => true) 
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
  
  def update_inherit_global_rules
    if @repository.nil?
      render_404
      return false
    end
    
    @repository.inherit_global_rules = params[:inherit_global_rules]
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
  
  private
  def clear_globals
    @repository = nil
    @project = nil
    @ref_rules = nil
    @ref_rule = nil
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
    
    logger.debug "@repository = #{@repository.inspect}"
    logger.debug "@project = #{@project.inspect}"  
    
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
  
  def symbolize(ref_rule)
    ref_rule.rule_type = ref_rule.rule_type.to_sym unless ref_rule.rule_type.nil?
    ref_rule.ref_type = ref_rule.ref_type.to_sym unless ref_rule.rule_type.nil?
  end
end
