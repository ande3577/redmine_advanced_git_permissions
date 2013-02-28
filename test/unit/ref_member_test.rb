require File.expand_path('../../test_helper', __FILE__)

class RefMemberTest < ActiveSupport::TestCase
  fixtures :repositories
  fixtures :users
  fixtures :groups_users
  
  def setup
    @user = User.where(:id => 2).first
    @group = Group.first
    
    @private_rule = RefRule.create(:repository => @repository, :rule_type => :private_ref, :expression => '[a-z]+', :ref_type => :branch, :regex => true)
    @private_rule.save
  end
  
  def test_create
    member = RefMember.create(:user => @user,  :ref_rule => @private_rule)
    assert member.save
    
    member.principal = @group
    assert member.save
    
    member.user_id = 99
    assert !member.save
    
    member.user = @user
    member.ref_rule_id = 99
    assert !member.save
    
    global_rule = RefRule.create(:rule_type => :illegal_ref, :expression => 'illegalglobal', :ref_type => :branch, :global => true)
    global_rule.save
    
    member.ref_rule = global_rule
    assert !member.save
    
    protected_rule = RefRule.create(:repository => @repository, :rule_type => :protected_ref, :expression => '[a-z]+', :ref_type => :branch, :regex => true)
    protected_rule.save
    
    member.ref_rule = protected_rule
    assert !member.save
    
  end
  
  def test_include
    member = RefMember.create(:user => @user,  :ref_rule => @private_rule)
    member.save
    
    assert member.include?(@user)
    assert !member.include?(User.first)
    
    member.principal = @group
    assert member.save
    
    assert !member.include?(@user)
    assert member.include?(@group.users.first)
  end
end
