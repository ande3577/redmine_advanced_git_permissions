require_dependency 'repositories_helper'

module GitPermissionsRepositoriesHelperPatch
  
  def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)
      base.class_eval do
          unloadable
          alias_method_chain :git_field_tags,        :manage_rules
      end
  end

  module ClassMethods
  end

  module InstanceMethods
    def git_field_tags_with_manage_rules(form, repository)
      gittags = git_field_tags_without_manage_rules(form, repository)
      
      unless repository.new_record?
      gittags << link_to(l(:label_manage_ref_rules), { :controller => "ref_rules", :action => "index", :repository_id => @repository })  
      end
      return gittags
    end
  end
  
end

RepositoriesHelper.send(:include, GitPermissionsRepositoriesHelperPatch)