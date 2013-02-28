# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html
get 'sys/git/:proj_name/branch/create', :to => "git_update#create_branch"
get 'sys/git/:proj_name/branch/update', :to => "git_update#update_branch"
get 'sys/git/:proj_name/branch/delete', :to => "git_update#delete_branch"
get 'sys/git/:proj_name/tag/create', :to => "git_update#create_tag"
get 'sys/git/:proj_name/tag/update', :to => "git_update#update_tag"
get 'sys/git/:proj_name/tag/delete', :to => "git_update#delete_tag"
get 'repositories/:repository_id/ref_rules', :to => "ref_rules#index"
put 'repositories/:repository_id/ref_rules/update_repository_settings', :to => "ref_rules#update_repository_settings"
get 'repositories/:repository_id/ref_rules/new', :to => "ref_rules#new"
post 'repositories/:repository_id/ref_rules/create', :to => "ref_rules#create"
get 'ref_rules/evaluate', :to => "ref_rules#evaluate"
get 'ref_rules/:id/evaluate', :to => "ref_rules#evaluate"
get 'ref_rules/:id/members', :to => "ref_rules#members"
post 'ref_rules/:id/members/add', :to => "ref_rules#add_members" 
delete 'ref_members/:member_id/delete', :to => "ref_rules#delete_member"
get 'repositories/:repository_id/ref_rules/evaluate', :to => "ref_rules#evaluate"
resources :ref_rules




