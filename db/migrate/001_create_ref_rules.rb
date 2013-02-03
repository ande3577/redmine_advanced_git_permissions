class CreateRefRules < ActiveRecord::Migration
  def change
    create_table :ref_rules do |t|
      t.integer :repository_id
      t.string :rule_type
      t.string :expression
      t.boolean :global, :default => false
      t.boolean :regex, :default=> false
      t.string :ref_type
    end
  end
end
