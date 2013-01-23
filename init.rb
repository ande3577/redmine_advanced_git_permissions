Redmine::Plugin.register :redmine_advanced_git_permissions do
  project_module :repository do
    permission :create_branch, :git_update => :create_branch
    permission :delete_branch, :git_update => :delete_branch
    permission :update_protected_branch, :git_update => :update_branch
    permission :create_tag, :git_update => :create_tag
    permission :delete_tag, :git_update => :delete_tag
    permission :update_tag, :git_update => :update_tag 
  end
  
  name 'Redmine Advanced Git Permissions plugin'
  author 'Author name'
  description 'This is a plugin for Redmine'
  version '0.0.1'
  url 'http://example.com/path/to/plugin'
  author_url 'http://example.com/about'
end
