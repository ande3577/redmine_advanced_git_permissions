require File.expand_path('../../test_helper', __FILE__)

require_dependency 'ref_rule'

class RefRuleTest < ActiveSupport::TestCase
  fixtures :repositories
  
  def setup
    @repository = Repository.first
  end

  # Replace this with your real tests.
  def test_create
    ref_rule = RefRule.create(:repository_id => @repository.id, :rule_type => :public_ref, :expression => '*', :ref_type => :branch)
        
    assert_equal @repository, ref_rule.repository, "repository after create"
    assert_equal :public_ref, ref_rule.rule_type, "rule type after create"
    assert_equal '*', ref_rule.expression, "expression after create"
    assert_equal :branch, ref_rule.ref_type, "ref type after create" 
    assert !ref_rule.global, "global after create"
    assert !ref_rule.regex, "not regex after create"
    assert ref_rule.save, "save tied to repository"
    
    ref_rule = RefRule.create(:rule_type => :public_ref, :expression => '*', :global=>true, :regex => true, :ref_type => :branch)
    assert_equal nil, ref_rule.repository, "create without repository"
    assert ref_rule.global, "global repository"
    assert ref_rule.regex, "regex after create"
    assert ref_rule.save, "save global"
    
    ref_rule = RefRule.create(:rule_type => :public_branch, :expression => '*', :ref_type => :branch)
    assert !ref_rule.save, "save without global or repository"
      
    ref_rule = RefRule.create(:repository => @repository, :rule_type => :public_branch, :ref_type => :branch)
    assert !ref_rule.save, "save without expression"
      
    ref_rule = RefRule.create(:repository => @repository, :rule_type => :public_branch, :expression  => '', :ref_type => :branch)
    assert !ref_rule.save, "save with empty expression"
  end
  
  def test_rule_type
    ref_rule = RefRule.create(:repository => @repository, :expression => '*', :ref_type => :branch)
    assert !ref_rule.save, "save without rule type"
      
    ref_rule.rule_type = :public_ref
    assert ref_rule.save, "save a public ref rule"
      
    ref_rule.rule_type = :protected_ref
    assert ref_rule.save, "save a protected ref rule"
      
    ref_rule.rule_type = :illegal_ref
    assert ref_rule.save, "save an illegal ref rule"
      
    ref_rule.rule_type = :invalid_rule
    assert !ref_rule.save, "fail to save invalid rule"
  end
  
  def test_ref_type
    ref_rule = RefRule.create(:repository => @repository, :rule_type => :public_ref, :expression => '*')
    assert !ref_rule.save, "without ref_type"
    
    ref_rule.ref_type = :branch
    assert ref_rule.save, "branch"
      
    ref_rule.ref_type = :tag
    assert ref_rule.save, "tag"
      
    ref_rule.ref_type = :invalid
    assert !ref_rule.save, "invalid"
      
  end
  
  def test_matches
    ref_rule = RefRule.create(:repository => @repository, :rule_type => :public_ref, :expression => 'master', :ref_type => :branch)
    assert ref_rule.matches?('master'), "check for exact match"
    assert !ref_rule.matches?('master1'), "check for exact match"  

    ref_rule.regex = true
        
    ref_rule.expression = '[a-z]+'
    assert ref_rule.matches?('hello'), "matches when it should";
    assert !ref_rule.matches?('hello1'), "doesn't match when it shouldn't";
    
    ref_rule.expression = '.*'
    assert ref_rule.matches?('aB c D 123 * _'), ".* matches anything";
    
  end
  
end
