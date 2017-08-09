class CreateProfiles < ActiveRecord::Migration
  def change
    create_table :profiles do |t|
      t.references :employee, null: false
      t.string :status
      t.datetime :start_date, null: false
      t.datetime :end_date
      t.string :business_title
      t.string :manager_id
      t.references :department, null: false
      t.references :location, null: false
      t.references :worker_type, null: false
      t.references :job_title, null: false
      t.string :company
      t.string :adp_assoc_oid
      t.string :adp_employee_id, null: false
    end
  end
end
