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
      buddy_id: buddy_id,
      cw_email: cw_email,
      cw_google_membership: cw_google_membership,
      notes: notes
    )
  end

  def build_security_profiles
    employee = Employee.find(employee_id)
    old_profile_ids = employee.security_profiles.map(&:id)
    new_profile_ids = security_profile_ids

    add_profile_ids = new_profile_ids - old_profile_ids
    revoke_profile_ids = old_profile_ids - new_profile_ids
    # wrap in a transaction, drop the old profiles and and the new ones
    # profiles to remove from user should have "revoked_at attr" updated with datetime and AD perms removed with a success code
    # add just creates new emp_sec_profiles
    #
    revoke_profile_ids.each do |sp_id|
      esp = EmpSecProfile.where("employee_id = ? AND security_profile_id = ? AND revoke_date IS NULL", employee_id, sp_id).first
      esp.update_attributes(revoke_date: Date.today)
    end unless revoke_profile_ids.blank?

    add_profile_ids.each do |sp_id|
      emp_transaction.emp_sec_profiles.build(security_profile_id: sp_id, employee_id: employee_id)
    end unless add_profile_ids.blank?
  end

  def build_machine_bundles
    unless machine_bundle_id.blank?
      machine_bundle = MachineBundle.find(machine_bundle_id)
      emp_transaction.emp_mach_bundles.build(
        machine_bundle_id: machine_bundle_id,
        employee_id: employee_id,
        details: {machine_bundle.name.to_sym => machine_bundle.description}
      )
    end
  end

  def save
    ActiveRecord::Base.transaction do
      build_security_profiles unless employee_id.blank?
      build_machine_bundles
      @emp_transaction.save
    end

    if @emp_transaction.errors.blank?
      unless security_profile_ids.blank?
        sas = SecAccessService.new(@emp_transaction)
        sas.apply_ad_permissions
      end
    else
      @errors = @emp_transaction.errors
    end
    errors.blank?
  end

end
