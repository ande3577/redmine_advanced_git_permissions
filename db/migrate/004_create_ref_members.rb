class CreateRefMembers < ActiveRecord::Migration
  def change
    create_table :ref_members do |t|
      t.integer :user_id
      t.integer :ref_rule_id
    end
  end
end
