require File.expand_path('../../test_helper', __FILE__)

require_dependency 'ref_rule'

class RepositoryTest < ActiveSupport::TestCase
  fixtures :repositories
  
  def setup
    @repository = Repository.first
    @rule = RefRule.create(:repository => @repository, :rule_type => :public_ref, :expression => '[a-zA-Z]+', :ref_type => :branch, :regex => true)
    @rule.save
    @protected_rule = RefRule.create(:repository => @repository, :rule_type => :protected_ref, :expression => '[a-z]+', :ref_type => :branch, :regex => true)
    @protected_rule.save
    @illegal_rule = RefRule.create(:repository => @repository, :rule_type => :illegal_ref, :expression => 'illegal', :ref_type => :branch)
    @illegal_rule.save
    @global_rule = RefRule.create(:rule_type => :illegal_ref, :expression => 'illegalglobal', :ref_type => :branch, :global => true)
    @global_rule.save
    @tag_rule = RefRule.create(:repository => @repository, :rule_type => :public_ref, :expression => 'tag', :ref_type => :tag, :regex => true)
    @tag_rule.save
  end
  
  def test_inherit_global_rules
    assert_equal false, @repository.inherit_global_rules
    @repository.inherit_global_rules = true
    assert_equal true, @repository.inherit_global_rules
  end
  
  def test_ref_rules
    assert_equal @rule.id, @repository.ref_rules.first.id, "test ref_rules accessor"
    assert_equal 4, @repository.ref_rules.count, "number or repositories (includes global)"
    
    @repository.inherit_global_rules = true
    assert_equal 5, @repository.ref_rules.count, "number or repositories (includes global)"
  end
  
  def test_evaluate
    @repository.inherit_global_rules = true
    assert_equal :illegal_ref, @repository.evaluate_ref(:branch, 'illegal'), "illegal ref"
    assert_equal :illegal_ref, @repository.evaluate_ref(:branch, 'illegalglobal'), "illegal global ref with inherit enabled"
    assert_equal :protected_ref, @repository.evaluate_ref(:branch, 'protected'), "protected ref"
    assert_equal :public_ref, @repository.evaluate_ref(:branch, 'Public'), "public branch"
    assert_equal :illegal_ref, @repository.evaluate_ref(:branch, 'invalid ref name'), "invalid branch name"
    
    assert_equal :illegal_ref, @repository.evaluate_ref(:tag, 'Public'), "branch rules don't affect tags"
    assert_equal :public_ref, @repository.evaluate_ref(:tag, 'tag'), "tag rules can be looked up"
    
    @repository.ref_rules.each { |r| r.destroy }
    assert_equal :public_ref, @repository.evaluate_ref(:branch, 'illegal'), 'public if no rules present'
  end
end