require 'redmine'

require_dependency 'git_permissions_repository_patch'
require_dependency 'git_permissions_repositories_helper_patch'
require_dependency 'git_permissions_hook_listener'

Redmine::Plugin.register :redmine_advanced_git_permissions do
  project_module :repository do
    permission :create_ref, :git_update => [:create_branch, :create_tag]
    permission :delete_ref, :git_update => [:delete_branch]
    permission :non_ff_update, :git_update => :update_branch
    permission :update_protected_ref, :git_update => [:update_protected_ref]
    permission :create_protected_ref, :git_update => [:create_protected_ref]
    permission :delete_protected_ref, :git_update => [:delete_protected_ref]
    permission :non_ff_protected_update, :git_update => :update_protected_ref
    permission :delete_tag, :git_update => :delete_tag
    permission :update_tag, :git_update => :update_tag 
    permission :delete_illegal_ref, :git_update => :delete_illegal_ref
    permission :manage_private_ref, :git_update => :manage_private_ref
    permission :manage_ref_rules, { :ref_rules => [ :index, :show, :create, :new, :edit, :destroy, :update, :update_repository_settings, :evaluate, :members, :add_members, :import ] }
  end
  
  # placholder to keep the hash from being removed
  settings :default => {:require_annotated_tag => 0, :default_branch_rule => :public_ref, :default_tag_rule => :public_ref, :dummy_setting => ""}, :partial => 'settings/advanced_git_permissions'
  
  name 'Redmine Advanced Git Permissions plugin'
  author 'David Anderson'
  description 'Allow for advanced git repository permissions management'
  version '0.0.1'
  url 'https://github.com/ande3577/redmine_advanced_git_permissions'
  author_url 'https://github.com/ande3577'
end
