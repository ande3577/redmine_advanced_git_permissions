module RefRulesHelper
  def options_for_repository_input
    html = options_for_select([]) # Blank

    Project.visible.sort.each do |p|
      if !p.repositories.empty? and User.current.allowed_to?(:commit_access, p) and User.current.allowed_to?(:manage_ref_rules, p)
        html << content_tag(:optgroup,
                options_for_select(p.repositories.where("id != ?", @repository.id).collect { |item| [item.name, item.id]}, nil),
                :label => p.to_s )
      end
    end
    return html
  end
end
