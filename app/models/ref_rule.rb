class RefRuleValidator < ActiveModel::Validator
  def validate(record)
    if record.rule_type == :private_ref and record.global
      record.errors[:base] << "Cannot create global private ref"
    end
  end
end

class RefRule < ActiveRecord::Base
  unloadable
  
  include Redmine::SafeAttributes
  
  safe_attributes 'repository_id', 'rule_type', 'expression', 'global', 'regex', 'ref_type'
  
  has_many :ref_members, :dependent => :destroy, :include => :principal, :conditions => "#{User.table_name}.type='User' AND #{User.table_name}.status=#{User::STATUS_ACTIVE}"
  
  belongs_to :repository
  validates_presence_of :repository, :unless => :global
  validates :rule_type, :inclusion => { :in => [:public_ref, :protected_ref, :private_ref, :illegal_ref] }
  validates_presence_of :expression
  validates :ref_type, :inclusion => { :in => [:branch, :tag] }
  validates_with RefRuleValidator
  
  def copy
    RefRule.new(:repository => repository, :rule_type => rule_type, 
      :ref_type => ref_type, :expression => expression, :regex => regex, :global => global)
  end
  
  def matches?(branch)
    RefRule.evaluate(branch, expression, regex)
  end
  
  def ref_members
    RefMember.where(:ref_rule_id => self)
  end
  
  def includes_member?(user)
    ref_members.each do |member|
      return true if member.include?(user)
    end
    false
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
    [:public_ref, :protected_ref, :private_ref, :illegal_ref]
  end
  
end
