module Employee::SecurityProfiles
  def active_security_profiles
    self.security_profiles.references(:emp_transactions).references(:emp_sec_profiles).where(emp_sec_profiles: {revoking_transaction_id: nil})
  end

  def security_profiles_to_revoke
    current_sps = self.security_profiles.references(:emp_transactions).references(:emp_sec_profiles).where(emp_sec_profiles: {revoking_transaction_id: nil})
    current_department_sps = SecurityProfile.find_profiles_for(self.department.id)
    current_sps - current_department_sps
  end

  def revoked_security_profiles
    self.security_profiles.references(:emp_sec_profiles).where("emp_sec_profiles.revoking_transaction_id IS NOT NULL")
  end

  def add_basic_security_profile
    default_sec_group = ""

    if self.worker_type.kind == "Regular"
      default_sec_group = SecurityProfile.find_by(name: "Basic Regular Worker Profile").id
    elsif self.worker_type.kind == "Temporary"
      default_sec_group = SecurityProfile.find_by(name: "Basic Temp Worker Profile").id
    elsif self.worker_type.kind == "Contractor"
      default_sec_group = SecurityProfile.find_by(name: "Basic Contract Worker Profile").id
    end

    emp_trans = EmpTransaction.new(
      kind: "Service",
      notes: "Initial provisioning by Mezzo",
      employee_id: self.id
    )

    emp_trans.emp_sec_profiles.build(security_profile_id: default_sec_group)

    emp_trans.save!

    if emp_trans.emp_sec_profiles.count > 0
      sas = SecAccessService.new(emp_trans)
      sas.apply_ad_permissions
    end
  end

end
