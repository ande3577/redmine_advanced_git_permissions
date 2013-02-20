class AddInheritGlobalToRepository < ActiveRecord::Migration
  def change
    add_column :repositories, :inherit_global_rules, :boolean, :default => false 
  end
end