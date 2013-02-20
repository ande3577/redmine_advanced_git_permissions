class AddDefaultRefRuleToRepository < ActiveRecord::Migration
  def change
    add_column :repositories, :default_branch_rule, :string
    add_column :repositories, :default_tag_rule, :string
  end
end