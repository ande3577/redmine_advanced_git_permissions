require File.expand_path('../../test_helper', __FILE__)
#require 'Redmine/Scm/Git'

require_dependency 'ref_rule'

class GitUpdateControllerTest < ActionController::TestCase
  fixtures :projects
  fixtures :users
  fixtures :roles
  fixtures :members
  fixtures :member_roles
  
  def setup
    @project = Project.where(:id => 1).first
    @project.enable_module!(:repository)
    @repository = @project.repositories.first
    @repository.enable_advanced_permissions = true
    @repository.save
    
    @user = User.where(:id => 2).first
    @admin = User.where(:admin => true).first
    
    Setting.sys_api_enabled = '1'
    @api_key = 'my_secret_key'
    Setting.sys_api_key = @api_key
    
  end
  
  def test_ws_key
    get(:update_branch, {:branch => "master", :proj_name => Project.first.name, :user_name => @admin.login, :ff => "1", :repository => @repository.url, :key => @api_key })
    assert_response 200
        
    get(:update_branch, {:branch => "master", :proj_name => Project.first.name, :user_name => @admin.login, :ff => "1", :repository => @repository.url, :key => 'wrong_key' })
    assert_response 403
    
    with_settings :sys_api_enabled => '0' do
      get(:update_branch, {:branch => "master", :proj_name => Project.first.name, :user_name => @admin.login, :ff => "1", :repository => @repository.url, :key => @api_key })
      assert_response 403
    end
  end
  
  # Replace this with your real tests.
  def test_invalid_project
    get(:create_branch, {:branch => "master", :proj_name => "invalid_project", :user_name => @user.login, :repository => @repository.url, :key => @api_key})
    assert_response :missing, "Invalid Project"
  end
  
  def test_invalid_repository
    get(:create_branch, {:branch => "master", :proj_name => @project.name, :user_name => @admin.login, :key => @api_key})
    assert_response :missing, "missing repository"
      
    get(:create_branch, {:branch => "master", :proj_name => @project.name, :user_name => @admin.login, :repository => "/var/www/git/invalid_name.git", :key => @api_key})
    assert_response :missing, "Invalid repository name"
      
    get(:create_branch, {:branch => "master", :proj_name => @project.name, :user_name => @admin.login, :repository => @repository.url, :key => @api_key})
        assert_response :success, "repository present"
  end
  
  def test_no_user
    get(:create_branch, {:branch => "master", :proj_name => Project.first.name, :repository => @repository.url, :key => @api_key })
    assert_response 403, "no user id present"
  end
  
  def test_create_branch
    Role.find(1).add_permission! :commit_access
    
    get(:create_branch, {:branch => "master", :proj_name => Project.first.name, :user_name => @user.login, :repository => @repository.url, :key => @api_key})
    assert_response 403, "create branch without permission"
      
    get(:create_branch, {:branch => "master", :proj_name => Project.first.name, :user_name => @admin.login, :repository => @repository.url, :key => @api_key})
    assert_response :success, "create branch as admin"
      
    Role.find(1).add_permission! :create_ref
    get(:create_branch, {:branch => "master", :proj_name => Project.first.name, :user_name => @user.login, :repository => @repository.url, :key => @api_key})
    assert_response :success, "create branch with permission"
    
    get(:create_branch, {:proj_name => Project.first.name, :user_name => @user.login, :repository => @repository.url, :key => @api_key})
    assert_response :missing, "create branch without passing name"  
    
  end
  
  def test_update_branch
    get(:update_branch, {:branch => "master", :proj_name => Project.first.name, :user_name => @user.login, :ff => "1", :repository => @repository.url, :key => @api_key})
    assert_response 403, "update branch without permission"
      
    get(:update_branch, {:branch => "master", :proj_name => Project.first.name, :user_name => @admin.login, :ff => "1", :repository => @repository.url, :key => @api_key })
    assert_response 200, "update branch as admin"
      
    Role.find(1).add_permission! :commit_access
    get(:update_branch, {:branch => "master", :proj_name => Project.first.name, :user_name => @user.login, :ff => "1", :repository => @repository.url, :key => @api_key })
    assert_response 200, "update branch with permission"
      
    get(:update_branch, {:branch => "master", :proj_name => Project.first.name, :user_name => @user.login, :key => @api_key})
    assert_response 404, "update branch without specifying ff"
      
    get(:update_branch, {:branch => "master", :proj_name => Project.first.name, :user_name => @user.login, :ff => "0", :repository => @repository.url, :key => @api_key })
    assert_response 403, "non-ff update without permission"
      
    get(:update_branch, {:branch => "master", :proj_name => Project.first.name, :user_name => @user.login, :ff => "", :repository => @repository.url, :key => @api_key })
    assert_response 403, "non-ff update with empty param"
      
    get(:update_branch, {:branch => "master", :proj_name => Project.first.name, :user_name => @admin.login, :ff => "0", :repository => @repository.url, :key => @api_key })
    assert_response :success, "non-ff update as admin"
      
    Role.find(1).add_permission! :non_ff_update
    get(:update_branch, {:branch => "master", :proj_name => Project.first.name, :user_name => @user.login, :ff => "0", :repository => @repository.url, :key => @api_key })
    assert_response :success, "non-ff update with permission"
      
  end
  
  def test_delete_branch
    Role.find(1).add_permission! :commit_access
    
    get(:delete_branch, {:branch => "master", :proj_name => Project.first.name, :user_name => @user.login, :repository => @repository.url, :key => @api_key})
    assert_response 403, "delete branch without permission"
      
    get(:delete_branch, {:branch => "master", :proj_name => Project.first.name, :user_name => @admin.login, :repository => @repository.url, :key => @api_key})
    assert_response :success, "delete branch as admin"
      
    Role.find(1).add_permission! :delete_ref
    get(:delete_branch, {:branch => "master", :proj_name => Project.first.name, :user_name => @user.login, :repository => @repository.url, :key => @api_key})
    assert_response :success, "delete branch with permission"
    
    get(:delete_branch, {:proj_name => Project.first.name, :user_name => @user.login, :repository => @repository.url, :key => @api_key})
    assert_response :missing, "delete branch without passing name"
  end
  
  def test_create_tag
    Role.find(1).add_permission! :commit_access
    
    # create tag without permission
    get(:create_tag, {:tag => "v0.1", :proj_name => Project.first.name, :user_name => @user.login, :annotated => "1", :repository => @repository.url, :key => @api_key} )
    assert_response 403, "create tag without permission"
     
    get(:create_tag, {:tag => "v0.1", :proj_name => Project.first.name, :user_name => @admin.login, :annotated => "1", :repository => @repository.url, :key => @api_key} )
    assert_response :success, "create tag as admin"
   
    Role.find(1).add_permission! :create_ref
    get(:create_tag, {:tag => "v0.1", :proj_name => Project.first.name, :user_name => @user.login, :annotated => "1", :repository => @repository.url, :key => @api_key} )
    assert_response :success, "create tag with permission"
    
    get(:create_tag, {:proj_name => Project.first.name, :user_name => @admin.login, :annotated => "1", :repository => @repository.url, :key => @api_key} )
    assert_response :missing, "create tag without specifying name"
      
    get(:create_tag, {:tag => "v0.1", :proj_name => Project.first.name, :user_name => @admin.login, :repository => @repository.url, :key => @api_key} )
    assert_response :missing, "create tag without specifying annotated"
    
    get(:create_tag, {:tag => "v0.1", :proj_name => Project.first.name, :user_name => @admin.login, :annotated => "0", :repository => @repository.url, :key => @api_key} )
    assert_response 403, "create unannotated tag"
      
    Setting.plugin_redmine_advanced_git_permissions[:require_annotated_tag] = true
    get(:create_tag, {:tag => "v0.1", :proj_name => Project.first.name, :user_name => @admin.login, :annotated => "", :repository => @repository.url, :key => @api_key} )
    assert_response 403, "create unannotated tag, empty param"
      
    Setting.plugin_redmine_advanced_git_permissions[:require_annotated_tag] = false
    get(:create_tag, {:tag => "v0.1", :proj_name => Project.first.name, :user_name => @admin.login, :annotated => "", :repository => @repository.url, :key => @api_key} )
    assert_response 200, "create unannotated tag, when allowed"
    
  end
  
  def test_delete_tag
    Role.find(1).add_permission! :commit_access
    
    # delete tag without permission
    get(:delete_tag, {:tag => "v0.1", :proj_name => Project.first.name, :user_name => @user.login, :repository => @repository.url, :key => @api_key } )
    assert_response 403, "delete tag without permission"
      
    get(:delete_tag, {:tag => "v0.1", :proj_name => Project.first.name, :user_name => @admin.login, :repository => @repository.url, :key => @api_key } )
    assert_response :success, "delete tag as admin"
      
    Role.find(1).add_permission! :delete_tag
    get(:delete_tag, {:tag => "v0.1", :proj_name => Project.first.name, :user_name => @user.login, :repository => @repository.url, :key => @api_key } )
    assert_response :success, "delete tag with permission"
    
    get(:delete_tag, {:proj_name => Project.first.name, :user_name => @admin.login, :repository => @repository.url, :key => @api_key } )
    assert_response :missing, "delete tag without specifying name"
    
  end
  
  def test_update_tag
    Role.find(1).add_permission! :commit_access
    
    # update tag without permission
    get(:update_tag, {:tag => "v0.1", :proj_name => Project.first.name, :user_name => @user.login, :annotated => "1", :repository => @repository.url, :key => @api_key } )
    assert_response 403, "update tag without permission"
      
    get(:update_tag, {:tag => "v0.1", :proj_name => Project.first.name, :user_name => @admin.login, :annotated => "1", :repository => @repository.url, :key => @api_key} )
    assert_response :success, "update tag as admin"
      
    Role.find(1).add_permission! :update_tag
    get(:update_tag, {:tag => "v0.1", :proj_name => Project.first.name, :user_name => @user.login, :annotated => "1", :repository => @repository.url, :key => @api_key} )
    assert_response :success, "update tag with permission"
      
    get(:update_tag, {:proj_name => Project.first.name, :user_name => @admin.login, :annotated => "1", :repository => @repository.url, :key => @api_key} )
    assert_response :missing, "update tag without specifying name"
      
    get(:update_tag, {:tag => "v0.1", :proj_name => Project.first.name, :user_name => @admin.login, :repository => @repository.url, :key => @api_key} )
    assert_response :missing, "update tag without specifying annotated"
    
    Setting.plugin_redmine_advanced_git_permissions[:require_annotated_tag] = true  
    get(:update_tag, {:tag => "v0.1", :proj_name => Project.first.name, :user_name => @admin.login, :annotated => "", :repository => @repository.url, :key => @api_key} )
    assert_response 403, "update unannotated tag, empty param"
      
    Setting.plugin_redmine_advanced_git_permissions[:require_annotated_tag] = false
    get(:update_tag, {:tag => "v0.1", :proj_name => Project.first.name, :user_name => @admin.login, :annotated => "", :repository => @repository.url, :key => @api_key} )
    assert_response 200, "update_tag unannotated tag, when allowed"
  end
  
  def test_illegal_branch
    Role.find(1).add_permission! :commit_access
    
    illegal_rule = RefRule.create(:repository => @repository, :rule_type => :illegal_ref, :expression => '[a-z]+', :ref_type => :branch, :regex => true)
    illegal_rule.save
    
    get(:update_branch, {:branch => "master", :proj_name => Project.first.name, :user_name => @admin.login, :ff => "1", :repository => @repository.url, :key => @api_key })
    assert_response 403, "update illegal branch as admin"
      
    Role.find(1).add_permission! :delete_ref
    get(:delete_branch, {:branch => "master", :proj_name => Project.first.name, :user_name => @user.login, :repository => @repository.url, :key => @api_key})
    assert_response 403, "delete illegal branch"
      
    Role.find(1).add_permission! :delete_illegal_ref
    get(:delete_branch, {:branch => "master", :proj_name => Project.first.name, :user_name => @user.login, :repository => @repository.url, :key => @api_key})
    assert_response 200, "delete illegal branch with permission"
    
  end
  
  def test_protected_branch
    Role.find(1).add_permission! :commit_access
    protected_rule = RefRule.create(:repository => @repository, :rule_type => :protected_ref, :expression => '[a-z]+', :ref_type => :branch, :regex => true)
    protected_rule.save
    
    get(:update_branch, {:branch => "master", :proj_name => Project.first.name, :user_name => @user.login, :ff => "1", :repository => @repository.url, :key => @api_key })
    assert_response 403, "update protected branch without permission" 
      
    get(:update_branch, {:branch => "master", :proj_name => Project.first.name, :user_name => @admin.login, :ff => "1", :repository => @repository.url, :key => @api_key })
    assert_response 200, "update protected branch as admin"
      
    Role.find(1).add_permission! :update_protected_ref
    get(:update_branch, {:branch => "master", :proj_name => Project.first.name, :user_name => @user.login, :ff => "1", :repository => @repository.url, :key => @api_key })
    assert_response 200, "update protected branch with permission" 
      
    get(:create_branch, {:branch => "master", :proj_name => Project.first.name, :user_name => @user.login, :repository => @repository.url, :key => @api_key})
    assert_response 403, "create branch without permission"
    
    get(:update_tag, {:tag => "v0.1", :proj_name => Project.first.name, :user_name => @user.login, :annotated => "1", :repository => @repository.url, :key => @api_key } )
    assert_response 403, "update tag without permission"
    
    Role.find(1).add_permission! :delete_ref
    get(:delete_branch, {:branch => "master", :proj_name => Project.first.name, :user_name => @user.login, :repository => @repository.url, :key => @api_key})
    assert_response 403, "delete branch without permission"
      
    Role.find(1).add_permission! :delete_protected_ref
    get(:delete_branch, {:branch => "master", :proj_name => Project.first.name, :user_name => @user.login, :repository => @repository.url, :key => @api_key})
    assert_response 200, "delete ref with permission"
        
    Role.find(1).add_permission! :create_ref
    get(:create_branch, {:branch => "master", :proj_name => Project.first.name, :user_name => @user.login, :repository => @repository.url, :key => @api_key})
    assert_response 403, "create branch without permission"
      
    Role.find(1).add_permission! :create_protected_ref
    get(:create_branch, {:branch => "master", :proj_name => Project.first.name, :user_name => @user.login, :repository => @repository.url, :key => @api_key})
    assert_response 200, "create branch with permission"
      
    Role.find(1).add_permission! :non_ff_update
    get(:update_branch, {:branch => "master", :proj_name => Project.first.name, :user_name => @user.login, :ff => "0", :repository => @repository.url, :key => @api_key })
    assert_response 403, "non-ff protected branch without permission"
      
    Role.find(1).add_permission! :non_ff_protected_update
    get(:update_branch, {:branch => "master", :proj_name => Project.first.name, :user_name => @user.login, :ff => "0", :repository => @repository.url, :key => @api_key })
    assert_response 200, "non-ff protected branch with permission"
  end
  
  def test_private_branch
    Role.find(1).add_permission! :commit_access
    private_rule = RefRule.create(:repository => @repository, :rule_type => :private_ref, :expression => '[a-z]+', :ref_type => :branch, :regex => true)
    private_rule.save
    
    get(:update_branch, {:branch => "master", :proj_name => Project.first.name, :user_name => @user.login, :ff => "1", :repository => @repository.url, :key => @api_key })
    assert_response 403, "update private branch without permission"
      
    get(:update_branch, {:branch => "master", :proj_name => Project.first.name, :user_name => @admin.login, :ff => "1", :repository => @repository.url, :key => @api_key })
    assert_response 200, "update private branch as admin"
      
    
    Role.find(1).add_permission! :manage_private_ref
    get(:update_branch, {:branch => "master", :proj_name => Project.first.name, :user_name => @user.login, :ff => "1", :repository => @repository.url, :key => @api_key })
    assert_response 200, "update private branch with permission"
      
    Role.find(1).remove_permission! :manage_private_ref
    member = RefMember.create(:user => @user, :ref_rule => private_rule)
    member.save
    get(:update_branch, {:branch => "master", :proj_name => Project.first.name, :user_name => @user.login, :ff => "1", :repository => @repository.url, :key => @api_key })
    assert_response 200, "update private branch with permission"
    
  end
  
  def test_illegal_tag
    Role.find(1).add_permission! :commit_access
    
    illegal_rule = RefRule.create(:repository => @repository, :rule_type => :illegal_ref, :expression => '[a-z]+', :ref_type => :tag, :regex => true)
    illegal_rule.save
    
    get(:update_tag, {:tag => "illegaltag", :proj_name => Project.first.name, :user_name => @admin.login, :annotated => "1", :repository => @repository.url, :key => @api_key } )
    assert_response 403, "update illegal"
      
    Role.find(1).add_permission! :delete_tag
    get(:delete_tag, {:tag => "illegaltag", :proj_name => Project.first.name, :user_name => @user.login, :repository => @repository.url, :key => @api_key})
    assert_response 403, "delete illegal tag"
      
    Role.find(1).add_permission! :delete_illegal_ref
    get(:delete_tag, {:tag => "illegaltag", :proj_name => Project.first.name, :user_name => @user.login, :repository => @repository.url, :key => @api_key})
    assert_response 200, "delete illegal tag with permission"

  end
  
  def test_protected_tag
    Role.find(1).add_permission! :commit_access
    Role.find(1).add_permission! :update_tag
    
    protected_rule = RefRule.create(:repository => @repository, :rule_type => :protected_ref, :expression => '[a-z]+', :ref_type => :tag, :regex => true)
    protected_rule.save
    
    get(:update_tag, {:tag => "protectedtag", :proj_name => Project.first.name, :user_name => @user.login, :annotated => "1", :repository => @repository.url, :key => @api_key } )
    assert_response 403, "update protected tag without permission"
      
    get(:update_tag, {:tag => "protectedtag", :proj_name => Project.first.name, :user_name => @admin.login, :annotated => "1", :repository => @repository.url, :key => @api_key } )
    assert_response 200, "update protected tag as admin"
      
    Role.find(1).add_permission! :update_protected_ref
    get(:update_tag, {:tag => "protectedtag", :proj_name => Project.first.name, :user_name => @user.login, :annotated => "1", :repository => @repository.url, :key => @api_key } )
    assert_response 200, "update protected tag with permission"
  end
  
  def test_with_advanced_permissions_disabled
    Role.find(1).add_permission! :commit_access
    Role.find(1).add_permission! :update_tag
    
    protected_rule = RefRule.create(:repository => @repository, :rule_type => :protected_ref, :expression => '[a-z]+', :ref_type => :tag, :regex => true)
    protected_rule.save
    
    @repository.enable_advanced_permissions = false;
    @repository.save
    
    get(:update_tag, {:tag => "protectedtag", :proj_name => Project.first.name, :user_name => @user.login, :annotated => "1", :repository => @repository.url, :key => @api_key } )
    assert_response 200, "allow if advanced permissions disabled"
  end
  
  
end
