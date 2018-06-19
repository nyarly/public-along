class CreateApprovals < ActiveRecord::Migration
  def change
    create_table :approvals do |t|
      t.references :approver_designation
      t.references :emp_transaction
      t.references :request_emp_transaction
      t.string :status
      t.datetime :requested_at
      t.datetime :cancelled_at
      t.datetime :approved_at
      t.datetime :rejected_at
      t.datetime :executed_at

      t.timestamps
    end
  end
end
