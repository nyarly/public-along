class AddNotNullConstraints < ActiveRecord::Migration
  MISSING_VALUE = ""

  def up
    change_column_default :applications, :ad_controls, false
    change_column_default :emp_access_levels, :active, true
    change_column_default :offboarding_infos, :archive_data, false
    change_column_default :offboarding_infos, :replacement_hired, false
    change_column_default :onboarding_infos, :cw_email, false
    change_column_default :onboarding_infos, :cw_google_membership, false
    change_column_null :access_levels, :name, false, MISSING_VALUE
    change_column_null :applications, :name, false, MISSING_VALUE
    change_column_null :applications, :ad_controls, false, false
    change_column_null :departments, :name, false, MISSING_VALUE
    change_column_null :departments, :code, false, MISSING_VALUE
    change_column_null :departments, :status, false, MISSING_VALUE
    change_column_null :emp_access_levels, :active, false, false
    change_column_null :emp_transaction, :kind, false, MISSING_VALUE
    change_column_null :employee, :first_name, false, MISSING_VALUE
    change_column_null :employee, :last_name, false, MISSING_VALUE
    change_column_null :employee, :employee_id, false, MISSING_VALUE
    change_column_null :job_titles, :name, false, MISSING_VALUE
    change_column_null :job_titles, :code, false, MISSING_VALUE
    change_column_null :job_titles, :status, false, MISSING_VALUE
    change_column_null :locations, :name, false, MISSING_VALUE
    change_column_null :locations, :code, false, MISSING_VALUE
    change_column_null :locations, :status, false, MISSING_VALUE
    change_column_null :machine_bundles, :name, false, MISSING_VALUE
    change_column_null :offboarding_infos, :archive_data, false, false
    change_column_null :offboarding_infos, :replacement_hired, false, false
    change_column_null :onboarding_infos, :cw_email, false, false
    change_column_null :onboarding_infos, :cw_google_membership, false, false
    change_column_null :parent_orgs, :name, false, MISSING_VALUE
    change_column_null :parent_orgs, :code, false, MISSING_VALUE
    change_column_null :security_profiles, :name, false, MISSING_VALUE
    change_column_null :worker_types, :name, false, MISSING_VALUE
    change_column_null :worker_types, :code, false, MISSING_VALUE
    change_column_null :worker_types, :kind, false, MISSING_VALUE
  end

  def down
    change_column_default :applications, :ad_controls, nil
    change_column_default :emp_access_levels, :active, nil
    change_column_default :offboarding_infos, :archive_data, nil
    change_column_default :offboarding_infos, :replacement_hired, nil
    change_column_default :onboarding_infos, :cw_email, nil
    change_column_default :onboarding_infos, :cw_google_membership, nil
    change_column_null :access_levels, :name, true
    execute "UPDATE access_levels SET name = NULL WHERE name = '#{MISSING_VALUE}'"
    change_column_null :applications, :name, true
    execute "UPDATE applications SET name = NULL WHERE name = '#{MISSING_VALUE}'"
    change_column_null :applications, :ad_controls, true
    change_column_null :departments, :name, true
    execute "UPDATE departments SET name = NULL WHERE name = '#{MISSING_VALUE}'"
    change_column_null :departments, :code, true
    execute "UPDATE departments SET code = NULL WHERE code = '#{MISSING_VALUE}'"
    change_column_null :departments, :status, true
    execute "UPDATE departments SET status = NULL WHERE status = '#{MISSING_VALUE}'"
    change_column_null :emp_access_levels, :active, true
    change_column_null :emp_transactions, :kind, true
    execute "UPDATE emp_transactions SET kind = NULL WHERE kind = '#{MISSING_VALUE}'"
    change_column_null :employees, :first_name, true
    execute "UPDATE employees SET first_name = NULL WHERE first_name = '#{MISSING_VALUE}'"
    change_column_null :employees, :last_name, true
    execute "UPDATE employees SET last_name = NULL WHERE last_name = '#{MISSING_VALUE}'"
    change_column_null :employees, :employee_id, true
    execute "UPDATE employees SET employee_id = NULL WHERE employee_id = '#{MISSING_VALUE}'"
    change_column_null :job_titles, :name, true
    execute "UPDATE job_titles SET name = NULL WHERE name = '#{MISSING_VALUE}'"
    change_column_null :job_titles, :code, true
    execute "UPDATE job_titles SET code = NULL WHERE code = '#{MISSING_VALUE}'"
    change_column_null :job_titles, :status, true
    execute "UPDATE job_titles SET status = NULL WHERE status = '#{MISSING_VALUE}'"
    change_column_null :locations, :name, true
    execute "UPDATE locations SET name = NULL WHERE name = '#{MISSING_VALUE}'"
    change_column_null :locations, :code, true
    execute "UPDATE locations SET code = NULL WHERE code = '#{MISSING_VALUE}'"
    change_column_null :locations, :status, true
    execute "UPDATE locations SET status = NULL WHERE status = '#{MISSING_VALUE}'"
    change_column_null :machine_bundles, :name, true
    execute "UPDATE machine_bundles SET name = NULL WHERE name = '#{MISSING_VALUE}'"
    change_column_null :offboarding_infos, :archive_data, true
    change_column_null :offboarding_infos, :replacement_hired, true
    change_column_null :onboarding_infos, :cw_email, true
    change_column_null :onboarding_infos, :cw_google_membership, true
    change_column_null :parent_orgs, :name, true
    execute "UPDATE parent_orgs SET name = NULL WHERE name = '#{MISSING_VALUE}'"
    change_column_null :parent_orgs, :code, true
    execute "UPDATE parent_orgs SET code = NULL WHERE code = '#{MISSING_VALUE}'"
    change_column_null :security_profiles, :name, true
    execute "UPDATE security_profiles SET name = NULL WHERE name = '#{MISSING_VALUE}'"
    change_column_null :worker_types, :name, true
    execute "UPDATE worker_types SET name = NULL WHERE name = '#{MISSING_VALUE}'"
    change_column_null :worker_types, :code, true
    execute "UPDATE worker_types SET code = NULL WHERE code = '#{MISSING_VALUE}'"
    change_column_null :worker_types, :kind, true
    execute "UPDATE worker_types SET kind = NULL WHERE kind = '#{MISSING_VALUE}'"
  end
end
