require File.expand_path('../../test_helper', __FILE__)

require_dependency 'ref_rule'

class RepositoryTest < ActiveSupport::TestCase
  fixtures :repositories
  fixtures :users
  
  def setup
    @repository = Repository.first
    @repository.enable_advanced_permissions = true;
    @repository.save
    
    @tag_rule = RefRule.create(:repository => @repository, :rule_type => :public_ref, :expression => 'tag', :ref_type => :tag, :regex => true)
    @tag_rule.save
    @rule = RefRule.create(:repository => @repository, :rule_type => :public_ref, :expression => '[a-zA-Z]+', :ref_type => :branch, :regex => true)
    @rule.save
    @protected_rule = RefRule.create(:repository => @repository, :rule_type => :protected_ref, :expression => '[a-z]+', :ref_type => :branch, :regex => true)
    @protected_rule.save
    @private_rule = RefRule.create(:repository => @repository, :rule_type => :private_ref, :expression => 'private', :ref_type => :branch, :regex => true)
    @private_rule.save
    @illegal_rule = RefRule.create(:repository => @repository, :rule_type => :illegal_ref, :expression => 'illegal', :ref_type => :branch)
    @illegal_rule.save
    @global_rule = RefRule.create(:rule_type => :illegal_ref, :expression => 'illegalglobal', :ref_type => :branch, :global => true)
    @global_rule.save
  end
  
  def test_inherit_global_rules
    assert_equal false, @repository.inherit_global_rules
    @repository.inherit_global_rules = true
    assert_equal true, @repository.inherit_global_rules
  end
  
  def test_ref_rules
    assert_equal 5, @repository.ref_rules.count, "number or repositories (includes global)"
    
    #test the order
    assert_equal @illegal_rule, @repository.ref_rules[0]
    assert_equal @private_rule, @repository.ref_rules[1]
    assert_equal @protected_rule, @repository.ref_rules[2]
    assert_equal @rule, @repository.ref_rules[3]
    assert_equal @tag_rule, @repository.ref_rules[4]
    
    @repository.inherit_global_rules = true
    assert_equal 6, @repository.ref_rules.count, "number or repositories (includes global)"
      
    #test the order
    assert_equal @global_rule, @repository.ref_rules[0]
    assert_equal @illegal_rule, @repository.ref_rules[1]
    assert_equal @private_rule, @repository.ref_rules[2]
    assert_equal @protected_rule, @repository.ref_rules[3]
    assert_equal @rule, @repository.ref_rules[4]
    assert_equal @tag_rule, @repository.ref_rules[5]
      
  end
  
  def test_default_ref_rules
    Setting.plugin_redmine_advanced_git_permissions[:default_branch_rule] = :protected_ref
    Setting.plugin_redmine_advanced_git_permissions[:default_tag_rule] = :illegal_ref
    
    @repository.default_branch_rule = :unsupported_rule
    @repository.default_tag_rule = :public_ref
    assert_equal false, @repository.save

    @repository.default_branch_rule = :public_ref    
    @repository.default_tag_rule = :unsupported_rule
    assert_equal false, @repository.save
    
    @repository.default_branch_rule = nil
    @repository.default_tag_rule = :public_ref
    assert_equal true, @repository.save
    @repository.reload
    assert_equal nil, @repository.default_branch_rule
    assert_equal 'public_ref', @repository.default_tag_rule
    
    @repository.default_branch_rule = :public_ref
    @repository.default_tag_rule = nil
    assert_equal true, @repository.save
    @repository.reload
    assert_equal 'public_ref', @repository.default_branch_rule
    assert_equal nil, @repository.default_tag_rule
    
  end
  
  def test_evaluate
    user = User.find(2)
    @repository.inherit_global_rules = true
    assert_equal :illegal_ref, @repository.evaluate_ref(:branch, 'illegal', user), "illegal ref"
    assert_equal :illegal_ref, @repository.evaluate_ref(:branch, 'illegalglobal', user), "illegal global ref with inherit enabled"
    assert_equal :private_ref, @repository.evaluate_ref(:branch, 'private', user), "private ref"
    
    member = RefMember.create(:user => user, :ref_rule => @private_rule)
    member.save 

    assert_equal :public_ref, @repository.evaluate_ref(:branch, 'private', user), "private ref as member"
    
    assert_equal :protected_ref, @repository.evaluate_ref(:branch, 'protected', user), "protected ref"
    assert_equal :public_ref, @repository.evaluate_ref(:branch, 'Public', user), "public branch"
    Setting.plugin_redmine_advanced_git_permissions[:default_branch_rule] = :illegal_ref
    assert_equal :illegal_ref, @repository.evaluate_ref(:branch, 'invalid ref name', user), "unspecified branch name"  
    @repository.default_branch_rule = :protected_ref    
    assert_equal :protected_ref, @repository.evaluate_ref(:branch, 'invalid ref name', user), "unspecified branch name"
    
    Setting.plugin_redmine_advanced_git_permissions[:default_tag_rule] = :illegal_ref
    assert_equal :illegal_ref, @repository.evaluate_ref(:tag, 'Public', user), "branch rules don't affect tags"
    @repository.default_tag_rule = :protected_ref
    assert_equal :protected_ref, @repository.evaluate_ref(:tag, 'Public', user), "branch rules don't affect tags"
      
    assert_equal :public_ref, @repository.evaluate_ref(:tag, 'tag', user), "tag rules can be looked up"
  end
  
end