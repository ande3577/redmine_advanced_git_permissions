class GitPermissionsHookListener < Redmine::Hook::ViewListener
  render_on :view_repositories_show_contextual, 
    :partial => 'repositories/link_to_ref_rules'
end