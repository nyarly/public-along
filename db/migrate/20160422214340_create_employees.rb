class CreateEmployees < ActiveRecord::Migration
  def change
    create_table :employees do |t|
      t.string :email
      t.string :first_name
      t.string :last_name
      t.string :workday_username
      t.string :employee_id
      t.string :country
      t.datetime :hire_date
      t.datetime :contract_end_date
      t.datetime :termination_date
      t.string :job_family_id
      t.string :job_family
      t.string :job_profile_id
      t.string :job_profile
      t.string :business_title
      t.string :employee_type
      t.string :contingent_worker_id
      t.string :contingent_worker_type
      t.string :location_type
      t.string :location
      t.string :manager_id
      t.string :cost_center
      t.string :cost_center_id
      t.string :personal_mobile_phone
      t.string :office_phone
      t.string :home_address_1
      t.string :home_address_2
      t.string :home_city
      t.string :home_state
      t.string :home_zip
      t.string :image_code

      t.timestamps null: false
    end
  end
end
