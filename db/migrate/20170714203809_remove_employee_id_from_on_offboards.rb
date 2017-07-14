class RemoveEmployeeIdFromOnOffboards < ActiveRecord::Migration
  def up
    remove_column :onboarding_infos, :employee_id
    remove_column :offboarding_infos, :employee_id
  end

  def down
    add_column :onboarding_infos, :employee_id, :integer
    add_column :offboarding_infos, :employee_id, :integer

    OnboardingInfo.all.each do |o|
      emp = o.emp_transaction
      o.employee_id = emp.employee_id
      o.save!
    end

    OffboardingInfo.all.each do |o|
      emp = o.emp_transaction
      o.employee_id = emp.employee_id
      o.save!
    end

    change_column_null :onboarding_infos, :employee_id, false
    change_column_null :offboarding_infos, :employee_id, false
  end
end
