class AddEnableAdvancedPermissionsToRepository < ActiveRecord::Migration
  def change
    add_column :repositories, :enable_advanced_permissions, :boolean, :default => false 
  end
end