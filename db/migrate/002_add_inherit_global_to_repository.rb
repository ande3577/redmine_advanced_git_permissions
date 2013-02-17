class AddInheritGlobalToRepository < ActiveRecord::Migration
  def change
    add_column :repository_id, :inherit_global_rules, :boolean, :default => false 
  end
end