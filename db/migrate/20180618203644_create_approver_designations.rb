class CreateApproverDesignations < ActiveRecord::Migration
  def change
    create_table :approver_designations do |t|
      t.references :employee
      t.references :approver_designatable, polymorphic: true
      t.string :kind, null: false
      t.boolean :active, null: false, default: 't'

      t.timestamps
    end
  end
end
