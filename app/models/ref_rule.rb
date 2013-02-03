class RefRule < ActiveRecord::Base
  unloadable
  
  belongs_to :repository
  validates_presence_of :repository, :unless => :global
  validates :rule_type, :inclusion => { :in => [:public_ref, :protected_ref, :illegal_ref] }
  validates_presence_of :expression
  validates :ref_type, :inclusion => { :in => [:branch, :tag] }
  
  def matches?(branch)
    if(!regex)
      return branch == expression
    else
      return !branch.match(expression).nil? && branch.match(expression)[0] == branch      
    end
  end
  
end
