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
  attribute :event_id, Integer
  attribute :link_email, String
  attribute :linked_account_id, Integer

  def initialize(params)
    params.each do |key, value|
      instance_variable_set("@#{key}", value)
    end

    @employee ||= find_employee
  end

  def errors
    return @errors ||= ActiveModel::Errors.new(self)
  end

  def find_employee
    if employee_id.present?
      employee = Employee.find employee_id

    # employee transaction for rehire or job change
    elsif event_id.present?
      profiler = EmployeeProfile.new
      event = AdpEvent.find event_id
      # if linking hire or rehire event to existing employee record
      if link_email == "on"
        if linked_account_id.present?
          employee = profiler.link_accounts(linked_account_id, event_id)
          event.status = "Processed"
          event.save!
          employee
        else
          emp_transaction.errors.add(:base, :employee_blank, message: "You didn't chose an email to reuse. Did you mean to create a new email? If so, please select 'no' in the Rehire or Worker Type Change.")
        end
      # if rehire or job change, but wish to have new record/email
      elsif link_email == "off"
        employee = profiler.new_employee(event)
        event.status = "Processed"
        event.save!
        ads = ActiveDirectoryService.new
        ads.create_disabled_accounts([employee])
        employee
      else
        # for new emp transactions before form filled out
        employee = profiler.build_employee(event)
      end
    else
      # no employee or event
      errors.add(:base, :employee_blank, message: "Employee can not be blank. Please revisit email link to refresh page.")
      return nil
    end
    employee
  end

  def emp_transaction
    emp_id = @employee.present? ? @employee.id : nil
    @emp_transaction ||= EmpTransaction.new(
      kind: kind,
      user_id: user_id,
      notes: notes,
      employee_id: emp_id
    )
  end

  def build_security_profiles
    # The security access form automatically understands old department security profiles to be unchecked
    # It will automatically add those to revoke_profile_ids
    if security_profile_ids.present?

      old_profile_ids = @employee.active_security_profiles.present? ? @employee.active_security_profiles.pluck(:id).map(&:to_i) : []
      new_profile_ids = security_profile_ids.map(&:to_i)

      add_profile_ids = new_profile_ids - old_profile_ids
      revoke_profile_ids = old_profile_ids - new_profile_ids

      revoke_profile_ids.each do |sp_id|
        esp_to_revoke = @employee.emp_sec_profiles.where("security_profile_id = ? AND revoking_transaction_id IS NULL", sp_id).last
        emp_transaction.revoked_emp_sec_profiles << esp_to_revoke
      end unless revoke_profile_ids.blank?

      add_profile_ids.each do |sp_id|
        emp_transaction.emp_sec_profiles.build(security_profile_id: sp_id)
      end unless add_profile_ids.blank?
    end
  end

  def build_machine_bundles
    machine_bundle = MachineBundle.find(machine_bundle_id)
    emp_transaction.emp_mach_bundles.build(
      machine_bundle_id: machine_bundle_id,
      details: {machine_bundle.name.to_sym => machine_bundle.description}
    )
  end

  def build_onboarding
    emp_transaction.onboarding_infos.build(
      buddy_id: buddy_id,
      cw_email: cw_email,
      cw_google_membership: cw_google_membership
    )
  end

  def build_offboarding
    emp_transaction.offboarding_infos.build(
      archive_data: archive_data,
      replacement_hired: replacement_hired,
      forward_email_id: forward_email_id,
      reassign_salesforce_id: reassign_salesforce_id,
      transfer_google_docs_id: transfer_google_docs_id
    )
  end

  def save
    ActiveRecord::Base.transaction do
      if @errors.blank? and @employee.present?
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
        emp_transaction.save!
      else
        emp_transaction.errors.add(:base, :employee_blank, message: "Employee can not be blank. Please revisit email link to refresh page.")
        raise ActiveRecord::RecordInvalid.new(emp_transaction)
      end

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
