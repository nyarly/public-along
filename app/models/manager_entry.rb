# Form Model

class ManagerEntry
  include Virtus.model

  extend ActiveModel::Naming
  include ActiveModel::Conversion
  include ActiveModel::Validations

  attribute :kind, String
  attribute :employee_id, Integer
  attribute :user_id, Integer
  attribute :buddy_id, Integer
  attribute :cw_email, Boolean
  attribute :cw_google_membership, Boolean
  attribute :archive_data, Boolean
  attribute :replacement_hired, Boolean
  attribute :forward_email_id, Integer
  attribute :reassign_salesforce_id, Integer
  attribute :transfer_google_docs_id, Integer
  attribute :security_profile_ids, Array[Integer]
  attribute :machine_bundle_id, Integer
  attribute :notes, String

  def errors
    return @errors ||= {}
  end

  def emp_transaction
    @emp_transaction ||= EmpTransaction.new(
      kind: kind,
      user_id: user_id,
      notes: notes
    )
  end

  def build_security_profiles
    employee = Employee.find(employee_id)

    # The security access form automatically understands old department security profiles to be unchecked
    # It will automatically add those to revoke_profile_ids
    old_profile_ids = employee.active_security_profiles.map(&:id)
    new_profile_ids = security_profile_ids

    add_profile_ids = new_profile_ids - old_profile_ids
    revoke_profile_ids = old_profile_ids - new_profile_ids

    revoke_profile_ids.each do |sp_id|
      esp = EmpSecProfile.where("employee_id = ? AND security_profile_id = ? AND revoking_transaction_id IS NULL", employee_id, sp_id).first
      emp_transaction.revoked_emp_sec_profiles << esp
    end unless revoke_profile_ids.blank?

    add_profile_ids.each do |sp_id|
      emp_transaction.emp_sec_profiles.build(security_profile_id: sp_id, employee_id: employee_id)
    end unless add_profile_ids.blank?
  end

  def build_machine_bundles
    machine_bundle = MachineBundle.find(machine_bundle_id)
    emp_transaction.emp_mach_bundles.build(
      machine_bundle_id: machine_bundle_id,
      employee_id: employee_id,
      details: {machine_bundle.name.to_sym => machine_bundle.description}
    )
  end

  def build_onboarding
    emp_transaction.onboarding_infos.build(
      employee_id: employee_id,
      buddy_id: buddy_id,
      cw_email: cw_email,
      cw_google_membership: cw_google_membership
    )
  end

  def build_offboarding
    emp_transaction.offboarding_infos.build(
      employee_id: employee_id,
      archive_data: archive_data,
      replacement_hired: replacement_hired,
      forward_email_id: forward_email_id,
      reassign_salesforce_id: reassign_salesforce_id,
      transfer_google_docs_id: transfer_google_docs_id
    )
  end

  def save
    ActiveRecord::Base.transaction do
      if !employee_id.blank?
        if kind == "Onboarding"
          build_onboarding
          build_security_profiles
          build_machine_bundles
        elsif kind == "Security Access"
          build_security_profiles
        elsif kind == "Offboarding"
          build_offboarding
        elsif kind == "Equipment"
          build_machine_bundles
        end
      else
        emp_transaction.errors.add(:base, :employee_blank, message: "Employee can not be blank. Please revisit email link to refresh page.")
        raise ActiveRecord::RecordInvalid.new(emp_transaction)
      end

      emp_transaction.save!

      if immediately_update_security_profiles?
        if emp_transaction.emp_sec_profiles.count > 0 || emp_transaction.revoked_emp_sec_profiles.count > 0
          sas = SecAccessService.new(emp_transaction)
          sas.apply_ad_permissions
        end

        if emp_transaction.revoked_emp_sec_profiles.count > 0
          emp_transaction.revoked_emp_sec_profiles.update_all(revoking_transaction_id: @emp_transaction.id)
        end
      end

      emp_transaction.errors.blank?
    end

    rescue ActiveRecord::RecordInvalid => e
      @errors = emp_transaction.errors
      errors.blank?
  end

  private

  def immediately_update_security_profiles?
    kind == "Onboarding" || kind == "Security Access"
  end

end
