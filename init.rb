require 'redmine'

require_dependency 'git_permissions_repository_patch'
require_dependency 'git_permissions_repositories_helper_patch'

Redmine::Plugin.register :redmine_advanced_git_permissions do
  project_module :repository do
    permission :create_branch, :git_update => :create_branch
    permission :delete_branch, :git_update => :delete_branch
    permission :update_protected_branch, :git_update => :update_branch
    permission :non_ff_update, :git_update => :update_branch
    permission :create_tag, :git_update => :create_tag
    permission :delete_tag, :git_update => :delete_tag
    permission :update_tag, :git_update => :update_tag 
    permission :update_protected_tag, :git_update => :update_tag
    permission :manage_ref_rules, { :ref_rules => [ :index, :show, :create, :new, :edit, :destroy, :update, :update_inherit_global_rules ] }
  end
  
  # placholder to keep the hash from being removed
  settings :default => {:require_annotated_tag => 0, :dummy_setting => ""}, :partial => 'settings/advanced_git_permissions'
  
  name 'Redmine Advanced Git Permissions plugin'
  author 'Author name'
  description 'This is a plugin for Redmine'
  version '0.0.1'
  url 'http://example.com/path/to/plugin'
  author_url 'http://example.com/about'
end
