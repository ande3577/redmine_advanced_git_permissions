# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html
get ':proj_name/branch/:branch_name/create', :to => "git_update#create_branch"
get ':proj_name/branch/:branch_name/update', :to => "git_update#update_branch"
get ':proj_name/branch/:branch_name/delete', :to => "git_update#delete_branch"
get ':proj_name/tag/:tag_name/create', :to => "git_update#create_tag"
get ':proj_name/tag/:tag_name/update', :to => "git_update#update_tag"
get ':proj_name/tag/:tag_name/delete', :to => "git_update#delete_tag"
