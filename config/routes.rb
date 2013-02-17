# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html
get 'projects/:proj_name/branch/create', :to => "git_update#create_branch"
get 'projects/:proj_name/branch/update', :to => "git_update#update_branch"
get 'projects/:proj_name/branch/delete', :to => "git_update#delete_branch"
get 'projects/:proj_name/tag/create', :to => "git_update#create_tag"
get 'projects/:proj_name/tag/update', :to => "git_update#update_tag"
get 'projects/:proj_name/tag/delete', :to => "git_update#delete_tag"
get 'repositories/:repository_id/ref_rules', :to => "ref_rules#index"
put 'repositories/:repository_id/ref_rules/update_inherit_global_rules', :to => "ref_rules#update_inherit_global_rules"
get 'repositories/:repository_id/ref_rules/new', :to => "ref_rules#new"
post 'repositories/:repository_id/ref_rules/create', :to => "ref_rules#create"
resources :ref_rules
put 'ref_rules/evaluate', :to => "ref_rules#evaluate"


