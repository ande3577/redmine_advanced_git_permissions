require File.expand_path('../../test_helper', __FILE__)

class GitUpdateControllerTest < ActionController::TestCase
  fixtures :projects
  fixtures :users
  fixtures :repositories
  fixtures :roles
  fixtures :members
  fixtures :member_roles
  
  def setup
    @project = Project.where(:id => 1).first
    @project.enable_module!(:repository)
    
    @user = User.where(:id => 2).first
    @admin = User.where(:admin => true).first
  end
  
  # Replace this with your real tests.
  def test_invalid_project
    get(:create_branch, {:branch => "master", :proj_name => "invalid_project", :user_name => @user.login})
    assert_response :missing, "Invalid Project"
  end
  
  def test_no_user
    get(:create_branch, {:branch => "master", :proj_name => Project.first.name})
    assert_response 403, "no user id present"
  end
  
  def test_create_branch
    Role.find(1).add_permission! :commit_access
    
    get(:create_branch, {:branch => "master", :proj_name => Project.first.name, :user_name => @user.login})
    assert_response 403, "create branch without permission"
      
    get(:create_branch, {:branch => "master", :proj_name => Project.first.name, :user_name => @admin.login})
    assert_response :success, "create branch as admin"
      
    Role.find(1).add_permission! :create_branch
    get(:create_branch, {:branch => "master", :proj_name => Project.first.name, :user_name => @user.login})
    assert_response :success, "create branch with permission"
    
    get(:create_branch, {:proj_name => Project.first.name, :user_name => @user.login})
    assert_response :missing, "create branch without passing name"  
    
  end
  
  def test_update_branch
    get(:update_branch, {:branch => "master", :proj_name => Project.first.name, :user_name => @user.login, :ff => true })
    assert_response 403, "update branch without permission"
      
    get(:update_branch, {:branch => "master", :proj_name => Project.first.name, :user_name => @admin.login, :ff => true })
    assert_response 200, "update branch as admin"
      
    Role.find(1).add_permission! :commit_access
    get(:update_branch, {:branch => "master", :proj_name => Project.first.name, :user_name => @user.login, :ff => true })
    assert_response 200, "update branch with permission"
      
    get(:update_branch, {:branch => "master", :proj_name => Project.first.name, :user_name => @user.login})
    assert_response 404, "update branch without specifying ff"
      
    get(:update_branch, {:branch => "master", :proj_name => Project.first.name, :user_name => @user.login, :ff => false })
    assert_response 403, "non-ff update without permission"
      
    get(:update_branch, {:branch => "master", :proj_name => Project.first.name, :user_name => @admin.login, :ff => false })
    assert_response :success, "non-ff update as admin"
      
    Role.find(1).add_permission! :non_ff_update
    get(:update_branch, {:branch => "master", :proj_name => Project.first.name, :user_name => @user.login, :ff => false })
    assert_response :success, "non-ff update with permission"
      
  end
  
  def test_delete_branch
    Role.find(1).add_permission! :commit_access
    
    get(:delete_branch, {:branch => "master", :proj_name => Project.first.name, :user_name => @user.login})
    assert_response 403, "delete branch without permission"
      
    get(:delete_branch, {:branch => "master", :proj_name => Project.first.name, :user_name => @admin.login})
    assert_response :success, "delete branch as admin"
      
    Role.find(1).add_permission! :delete_branch
    get(:delete_branch, {:branch => "master", :proj_name => Project.first.name, :user_name => @user.login})
    assert_response :success, "delete branch with permission"
    
    get(:delete_branch, {:proj_name => Project.first.name, :user_name => @user.login})
    assert_response :missing, "delete branch without passing name"
  end
  
  def test_create_tag
    Role.find(1).add_permission! :commit_access
    
    # create tag without permission
    get(:create_tag, {:tag => "v0.1", :proj_name => Project.first.name, :user_name => @user.login} )
    assert_response 403, "crate tag without permission"
     
#    get(:create_tag, {:tag => "v0.1", :proj_name => Project.first.name, :user_name => @admin.login} )
#    assert_response 403, "crate tag as admin"
   
    Role.find(1).add_permission! :create_tag
    
  end
  
  def test_update_tag
  end
  
  def test_delete_tag
  end
  
end
