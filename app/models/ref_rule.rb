class RefRule < ActiveRecord::Base
  unloadable
  
  include Redmine::SafeAttributes
  
  safe_attributes 'repository_id', 'rule_type', 'expression', 'global', 'regex', 'ref_type'
  
  belongs_to :repository
  validates_presence_of :repository, :unless => :global
  validates :rule_type, :inclusion => { :in => [:public_ref, :protected_ref, :illegal_ref] }
  validates_presence_of :expression
  validates :ref_type, :inclusion => { :in => [:branch, :tag] }
  
  def matches?(branch)
    RefRule.evaluate(branch, expression, regex)
  end
  
  def self.evaluate(ref, expr, regx)
    if !regx
      return ref == expr
    else
      return (!ref.match(expr).nil?) && (ref.match(expr)[0] == ref)      
    end
  end
  
  def self.ref_types
    [:branch, :tag]
  end
  
  def self.rule_types
    [:public_ref, :protected_ref, :illegal_ref]
  end
  
end
