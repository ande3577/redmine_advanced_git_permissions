require File.expand_path('../../test_helper', __FILE__)

class RefRulesControllerTest < ActionController::TestCase
  fixtures :projects
  fixtures :users
  fixtures :roles
  fixtures :members
  fixtures :member_roles
  
  def setup
    @project = Project.where(:id => 1).first
    @project.enable_module!(:repository)
    @repository = @project.repositories.first
    
    @user = User.where(:id => 2).first
    @admin = User.where(:admin => true).first
    
    @protected_rule = RefRule.create(:repository => @repository, :rule_type => :protected_ref, :expression => '[a-z]+', :ref_type => :branch, :regex => true)
    @protected_rule.save
    @global_rule = RefRule.create(:rule_type => :illegal_ref, :expression => 'illegalglobal', :ref_type => :branch, :global => true)
    @global_rule.save
    
    Role.find(1).add_permission! :manage_ref_rules
  end
  
  # Replace this with your real tests.
  def test_index
    get :index
    assert_response 302, "get a global ref_rules page as anon"
      
    get :index, :repository_id => @repository.id
    assert_response 302, "get a project ref_rules page as anon"
      
    @request.session[:user_id] = @admin.id
    get :index
    assert_response 200
    ref_rules = assigns(:ref_rules)
    assert_equal 1, ref_rules.size
    assert_equal @global_rule, ref_rules.first 
    
    get :index, :repository_id => @repository.id
    assert_response 200
    ref_rules = assigns(:ref_rules)
    assert_equal 1, ref_rules.size
    assert_equal @protected_rule, ref_rules.first
    
    get :index, :repository_id => '99'
    assert_response 404, "invalid repository"
    
    @request.session[:user_id] = @user.id
    get :index
    assert_response 403
    
    get :index, :repository_id => @repository.id
    assert_response 200
    ref_rules = assigns(:ref_rules)
    assert_equal 1, ref_rules.size
    assert_equal @protected_rule, ref_rules.first
    
    Role.find(1).remove_permission! :manage_ref_rules
    Role.find(1).remove_permission! :commit_access
    
    get :index, :repository_id => @repository.id
    assert_response 403
    
    Role.find(1).add_permission! :commit_access
    get :index, :repository_id => @repository.id
    assert_response 200
  end
  
  def test_new
    get :new
    assert_response 302, "get new global ref_rule with no id"
      
    get :new, :repository_id => @repository.id
    assert_response 302, "get a new global ref_rule with no id"
      
    @request.session[:user_id] = @admin.id
    get :new
    assert_response 200, "get a new global ref_rule with no repository"
    assert_equal true, assigns(:ref_rule).global
    assert_equal nil, assigns(:ref_rule).repository
    
    get :new, :repository_id => @repository.id
    assert_response 200, "get a new ref_rule with repository"
    assert_equal false, assigns(:ref_rule).global
    assert_equal @repository, assigns(:ref_rule).repository
    
    @request.session[:user_id] = @user.id
    get :new
    assert_response 403, "get a global ref_rule with no id"  
    
    get :new, :repository_id => @repository.id
    assert_response 200, "get a new ref_rule with repository"
    assert_equal false, assigns(:ref_rule).global
    assert_equal @repository, assigns(:ref_rule).repository
    
  end
  
  def test_create
    post :create, :ref_rule => { :rule_type => :public_ref, :expression => "new_rule_as_anon", :global=>true, :regex => false, :ref_type => :branch }
    assert_redirected_to :controller => :account, :action => :login, :back_url => 'http://test.host/ref_rules'
    
    post :create, :ref_rule => { :repository_id => @repository.id, :rule_type => :public_ref, :expression => "new_rule_as_anon", :regex => false, :ref_type => :branch }
    assert_response 302, "create rule with repository without permission"
    
    @request.session[:user_id] = @admin.id
    flash[:error] = ""
    post :create, :ref_rule => { :global => false, :expression => "new_rule_as_admin", :regex => true, :ref_type => :branch, :rule_type => :public_ref }
    assert_equal "Cannot create rule!", flash[:error]      
    
    flash[:notice] = ""
    post :create, :ref_rule => { :rule_type => :public_ref, :expression => "new_rule_as_admin", :global=>true, :regex => false, :ref_type => :branch }
    assert_redirected_to :controller => :ref_rules, :action => :index
    assert_equal "Rule created.", flash[:notice]
    ref_rule = RefRule.last
    assert_equal true, ref_rule.global
    assert_equal :public_ref, ref_rule.rule_type.to_sym
    assert_equal "new_rule_as_admin", ref_rule.expression
    assert_equal :branch, ref_rule.ref_type.to_sym
    
    flash[:notice] = ""
    post :create, :repository_id => @repository.id, :ref_rule => { :rule_type => :public_ref, :expression => "new_rule_as_admin", :regex => false, :ref_type => :branch }
    assert_redirected_to :controller => :ref_rules, :action => :index, :repository_id => @repository
    assert_equal "Rule created.", flash[:notice]
    
    @request.session[:user_id] = @user.id
    post :create, :ref_rule => { :rule_type => :public_ref, :expression => "new_rule_as_user", :global=>true, :regex => false, :ref_type => :branch }
    assert_response 403, "create rule without permission"
      
    flash[:notice] = ""
    post :create, :repository_id => @repository.id, :ref_rule => { :rule_type => :public_ref, :expression => "new_rule_as_user", :regex => false, :ref_type => :branch }
    assert_redirected_to :controller => :ref_rules, :action => :index, :repository_id => @repository
    assert_equal "Rule created.", flash[:notice]
      
  end
  
  def test_edit
    get :edit, :id => @global_rule.id
    assert_response 302, "get a global ref_rule with no id"
       
    get :edit, :id => @protected_rule.id
    assert_response 302, "get a local ref_rule"
      
    @request.session[:user_id] = @admin.id
    get :edit, :id => @global_rule.id
    assert_response 200, "get a global ref_rule with no repository"
    assert_equal @global_rule, assigns(:ref_rule)
     
    get :edit, :id => @global_rule.id, :repository_id => @repository.id
    assert_response 404, "get a global rule with a repository id"
      
    get :edit, :id => @protected_rule.id, :repository_id => @repository.id
    assert_response 404
    
    
    get :edit, :id => @protected_rule.id
    assert_response 200
    assert_equal @protected_rule, assigns(:ref_rule)
    
    @request.session[:user_id] = @user.id
    get :edit, :id => @global_rule.id
    assert_response 403, "get a global ref_rule with no id"  
      
    get :edit, :id => @protected_rule.id
    assert_response 200
    assert_equal @protected_rule, assigns(:ref_rule)
  end
  
  def test_destroy
    delete :destroy, :id => @global_rule.id
    assert_redirected_to :controller => :account, :action => :login, :back_url => "http://test.host/ref_rules/#{@global_rule.id}"
       
    delete :destroy, :id => @protected_rule.id
    assert_redirected_to :controller => :account, :action => :login, :back_url => "http://test.host/ref_rules/#{@protected_rule.id}"
      
    @request.session[:user_id] = @admin.id
    
    delete :destroy, :id => @global_rule.id, :repository_id => @repository.id
    assert_response 404, "delete a global rule with a repository id"
      
    flash[:notice] = ""
    delete :destroy, :id => @global_rule.id
    assert_redirected_to :controller => :ref_rules, :action => :index
    assert_equal @global_rule, assigns(:ref_rule)
    assert_equal "Rule deleted.", flash[:notice]
    assert_equal true, RefRule.where(:id => @global_rule.id).empty?
    
    delete :destroy, :id => @global_rule.id
    assert_response 404, "delete a rule that was already deleted"
    
    get :edit, :id => @protected_rule.id, :repository_id => @repository.id
    assert_response 404
     
    flash[:notice] = ""
    get :destroy, :id => @protected_rule.id
    assert_redirected_to :controller => :ref_rules, :action => :index, :repository_id => @repository
    assert_equal "Rule deleted.", flash[:notice]
    assert_equal true, RefRule.where(:id => @protected_rule.id).empty?
    
    setup
    @request.session[:user_id] = @user.id
    get :destroy, :id => @global_rule.id
    assert_response 403, "get a global ref_rule with no id"  
    
    flash[:notice] = ""  
    get :destroy, :id => @protected_rule.id
    assert_redirected_to :controller => :ref_rules, :action => :index, :repository_id => @repository
    assert_equal "Rule deleted.", flash[:notice]
    assert_equal true, RefRule.where(:id => @protected_rule.id).empty?
  end
  
  def test_update
    put :update, :id => @global_rule.id, :ref_rule => { :rule_type => :public_ref, :expression => "new_rule_as_anon", :global=>true, :regex => false, :ref_type => :branch }
    assert_response 302, "create rule without permission"
    
    put :update, :id => @protected_rule.id, :ref_rule => { :rule_type => :public_ref, :expression => "new_rule_as_anon", :regex => false, :ref_type => :branch }
    assert_response 302, "create rule with repository without permission"
      
    @request.session[:user_id] = @admin.id
    put :update, :id => 0, :ref_rule => { :rule_type => :public_ref, :expression => "new_rule_as_anon", :global=>true, :regex => false, :ref_type => :branch }
    assert_response 404, "update nonexisting rule"
      
    flash[:notice] = ""
    put :update, :id => @global_rule.id, :ref_rule => { :rule_type => :protected_ref, :expression => "update_global_as_admin", :regex => true, :ref_type => :tag }
    assert_redirected_to :controller => :ref_rules, :action => :index
    assert_equal "Rule updated.", flash[:notice] 
    @global_rule.reload
    assert_equal :protected_ref, @global_rule.rule_type.to_sym
    assert_equal "update_global_as_admin", @global_rule.expression
    assert_equal true, @global_rule.regex
    assert_equal :tag, @global_rule.ref_type.to_sym
    
    #attempt to change global
    put :update, :id => @global_rule.id, :ref_rule => { :global => false, :repository_id => @repository.id, :rule_type => :illegal_ref, :expression => "update_global_as_admin", :regex => true, :ref_type => :tag }
    @global_rule.reload
    assert_equal true, @global_rule.global
    assert_equal nil, @global_rule.repository_id
    assert_equal :protected_ref, @global_rule.rule_type.to_sym
    
    #update nonglobal ref
    flash[:notice] = ""
    put :update, :id => @protected_rule.id, :ref_rule => { :rule_type => :public_ref, :expression => "update_nonglobal_as_admin", :regex => true, :ref_type => :tag }
    assert_redirected_to :controller => :ref_rules, :action => :index, :repository_id => @repository
    assert_equal "Rule updated.", flash[:notice] 
    @protected_rule.reload
    assert_equal :public_ref, @protected_rule.rule_type.to_sym
    assert_equal "update_nonglobal_as_admin", @protected_rule.expression
    assert_equal true, @protected_rule.regex
    assert_equal :tag, @protected_rule.ref_type.to_sym
    
    #attempt to change repository id
    repository2 = Repository.find(11)
    put :update, :id => @protected_rule.id, :repository_id => @repository.id, :ref_rule => { :repository_id => repository2.id, :rule_type => :illegal_ref, :expression => "update_nonglobal_as_admin", :regex => true, :ref_type => :tag }
    @protected_rule.reload
    assert_equal @repository.id, @protected_rule.repository_id
    assert_equal :public_ref, @protected_rule.rule_type.to_sym
    
    @request.session[:user_id] = @user.id 
    put :update, :id => @global_rule.id, :ref_rule => { :rule_type => :protected_ref, :expression => "update_global_as_user", :regex => true, :ref_type => :tag }
    assert_response 403
    
    flash[:notice] = ""
    put :update, :id => @protected_rule.id, :ref_rule => { :rule_type => :illegal_ref, :expression => "update_nonglobal_as_user", :regex => false, :ref_type => :branch }
    assert_redirected_to :controller => :ref_rules, :action => :index, :repository_id => @repository
    assert_equal "Rule updated.", flash[:notice] 
    @protected_rule.reload
    assert_equal :illegal_ref, @protected_rule.rule_type.to_sym
    assert_equal "update_nonglobal_as_user", @protected_rule.expression
    assert_equal false, @protected_rule.regex
    assert_equal :branch, @protected_rule.ref_type.to_sym
  end
  
  def test_evaluate
    @request.session[:user_id] = @admin.id
      
    put :evaluate, :id => @global_rule.id, :value => 'illegalglobal'
    assert_response 200, "no expression"
    assert_equal false, assigns(:matches), "no expression"
      
    put :evaluate, :id => @global_rule.id, :expression => "illegalglobal"
    assert_response 200, "evaluate a global ref_rule with no value"
    assert_equal false, assigns(:matches), "no value"
    
    put :evaluate, :id => @global_rule.id, :expression => "illegalglobal", :value => "illegalglobal"
    assert_response 200, "evaluate a global ref_rule"
    assert_equal true, assigns(:matches)
    
    put :evaluate, :id => @global_rule.id, :expression => "[a-z]+", :value => "9999", :regex => true
    assert_equal false, assigns(:matches)
    
    put :evaluate, :id => @global_rule.id, :expression => "[a-z]+", :value => "illegalglobal", :regex => true
    assert_equal true, assigns(:matches)
    
    put :evaluate, :id => @global_rule.id
    assert_response 200, "evaluate a global ref_rule with no value or expression"
    assert_equal false, assigns(:matches), "no match"
    
  end
  
  def test_update_repository_settings
    put :update_repository_settings, :repository_id => @repository.id
    assert_response 302, "create rule without permission"
    
    put :update_repository_settings, :repository_id => @repository.id
    assert_response 302, "create rule with repository without permission"
      
    @request.session[:user_id] = @user.id
      
    put :update_repository_settings, :repository_id => @repository.id, :inherit_global_rules => true, :default_branch_rule => 'illegal_ref', :default_tag_rule => 'protected_ref'
    assert_redirected_to :controller => :ref_rules, :action => :index, :repository_id => @repository
    assert_equal true, assigns(:repository).inherit_global_rules
    assert_equal :illegal_ref, assigns(:repository).default_branch_rule
    assert_equal :protected_ref, assigns(:repository).default_tag_rule
    
    Setting.plugin_redmine_advanced_git_permissions[:default_branch_rule] = :protected_ref
    Setting.plugin_redmine_advanced_git_permissions[:default_tag_rule] = :illegal_ref
    put :update_repository_settings, :repository_id => @repository.id, :inherit_global_rules => true, :default_branch_rule => 'default', :default_tag_rule => 'something_else'
    assert_equal nil, assigns(:repository).default_branch_rule
    assert_equal nil, assigns(:repository).default_tag_rule
  end
  
end
