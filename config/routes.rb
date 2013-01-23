# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html
get ':proj_name/branch/create', :to => "git_update#create_branch"
get ':proj_name/branch/update', :to => "git_update#update_branch"
get ':proj_name/branch/delete', :to => "git_update#delete_branch"
get ':proj_name/tag/create', :to => "git_update#create_tag"
get ':proj_name/tag/update', :to => "git_update#update_tag"
get ':proj_name/tag/delete', :to => "git_update#delete_tag"
