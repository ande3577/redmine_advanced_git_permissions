# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html
get ':proj_name/git/branch/create', :to => "git_update#create_branch"
get ':proj_name/git/branch/update', :to => "git_update#update_branch"
get ':proj_name/git/branch/delete', :to => "git_update#delete_branch"
get ':proj_name/git/tag/create', :to => "git_update#create_tag"
get ':proj_name/git/tag/update', :to => "git_update#update_tag"
get ':proj_name/git/tag/delete', :to => "git_update#delete_tag"
