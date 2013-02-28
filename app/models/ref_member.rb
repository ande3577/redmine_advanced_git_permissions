class RefMemberRefValidator < ActiveModel::Validator
  def validate(record)
    unless record.ref_rule.nil?
      if record.ref_rule.global
        record.errors[:base] << "Cannot assign member to global ref"
      end
      
      if record.ref_rule.rule_type.to_sym != :private_ref
        record.errors[:base] << "Can only assign member to private ref"
      end
    end
  end
end

class RefMember < ActiveRecord::Base
  unloadable
  
  belongs_to :user
  belongs_to :principal, :foreign_key => 'user_id'
  belongs_to :ref_rule
  validates_presence_of :principal, :ref_rule
  validates_with RefMemberRefValidator
  
  def include?(user)
    if principal.is_a?(Group)
      !user.nil? && user.groups.include?(principal)
    else
      self.user == user
    end
  end
  
end

