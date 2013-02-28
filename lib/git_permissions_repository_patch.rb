require_dependency 'repository'


module RepositoryPatch
  def self.included(base)
    
    base.send(:extend, ClassMethods)
    base.send(:include, InstanceMethods)
    base.class_eval do
      has_many :ref_rules
      validates :default_branch_rule, :inclusion => { :in => [nil, :public_ref, :protected_ref, :illegal_ref] }
      validates :default_tag_rule, :inclusion => { :in => [nil, :public_ref, :protected_ref, :illegal_ref] }
    end
  end
  
  module ClassMethods
  end
  
  module InstanceMethods
    def ref_rules
      order_string = "case ref_type
          when 'branch' then '1'
          when 'tag' then '2'
        end, 
        case rule_type
          when 'illegal_ref' then '1'
          when 'private_ref' then '2'
          when 'protected_ref' then '3'
          when 'public_ref' then '4'
        end"
      
      if inherit_global_rules
        return RefRule.where("repository_id = ? OR global = ?", id, true).
          order(order_string + ", global DESC")
      else
        return RefRule.where("repository_id = ?", id).order(order_string)
      end
    end
    
    def evaluate_ref(ref_type, ref_name, user)
      ref_rules.where(:ref_type => ref_type).each do |r|
        if r.matches?(ref_name)
          rule_type = r.rule_type.to_sym
          if rule_type == :private_ref and r.includes_member?(user)
            return :public_ref
          end
          return rule_type
        end
      end
        
      if ref_type == :branch
        return default_branch_rule unless default_branch_rule.nil?
        return Setting.plugin_redmine_advanced_git_permissions[:default_branch_rule].to_sym
      elsif ref_type == :tag
        return default_tag_rule unless default_tag_rule.nil?
        return Setting.plugin_redmine_advanced_git_permissions[:default_tag_rule].to_sym
      end
      :illegal_ref
    end
    
    private
    
    def matches?(ref_type, rule_type, ref_name)
      ref_rules.where("ref_type = ? AND rule_type = ?", ref_type, rule_type).each  { |r|
              if r.matches?(ref_name)
                return true
              end
      }
      false
    end
  end
end

Repository.send(:include, RepositoryPatch)