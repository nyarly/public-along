# Responsible for handling manager forms
class ManagerEntry
  include Virtus.model

  extend ActiveModel::Naming
  include ActiveModel::Conversion
  include ActiveModel::Validations

  attr_reader :emp_transaction

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
    @emp_transaction = emp_transaction
  end

  def errors
    @errors ||= ActiveModel::Errors.new(self)
  end

  def find_employee
    begin
      return worker if employee_id.present?
      return link_worker if link_accounts?
      return new_worker if needs_new_account?
      profile_builder.build_employee(event) if event.present?
    rescue
      errors.add(:base, :employee_blank, message: 'Something bad')
    end
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
    return true if security_profile_ids.blank?

    old_profile_ids = @employee.active_security_profiles.present? ? @employee.active_security_profiles.pluck(:id).map(&:to_i) : []
    new_profile_ids = security_profile_ids.map(&:to_i)

    add_profile_ids = new_profile_ids - old_profile_ids
    revoke_profile_ids = old_profile_ids - new_profile_ids

    revoke_profile_ids.each do |sp_id|
      esp_to_revoke = @employee.emp_sec_profiles.where('security_profile_id = ? AND revoking_transaction_id IS NULL', sp_id).last
      emp_transaction.revoked_emp_sec_profiles << esp_to_revoke
    end unless revoke_profile_ids.blank?

    add_profile_ids.each do |sp_id|
      emp_transaction.emp_sec_profiles.build(security_profile_id: sp_id)
    end unless add_profile_ids.blank?
  end

  def build_machine_bundles
    machine_bundle = MachineBundle.find(machine_bundle_id)
    emp_transaction.emp_mach_bundles.build(
      machine_bundle_id: machine_bundle_id,
      details: { machine_bundle.name.to_sym => machine_bundle.description }
    )
  end

  def build_onboard
    emp_transaction.onboarding_infos.build(
      buddy_id: buddy_id,
      cw_email: cw_email,
      cw_google_membership: cw_google_membership
    )
  end

  def build_offboard
    emp_transaction.offboarding_infos.build(
      archive_data: archive_data,
      replacement_hired: replacement_hired,
      forward_email_id: forward_email_id,
      reassign_salesforce_id: reassign_salesforce_id,
      transfer_google_docs_id: transfer_google_docs_id
    )
  end

  def save
    if @employee.blank? && event.blank?
      errors.add(:base, :employee_blank, message: 'Employee cannot be blank. Please revisit email link to refresh page.')
      return ActiveRecord::RecordInvalid.new(emp_transaction)
    else
      ActiveRecord::Base.transaction do
        begin
          build_transaction_data
          emp_transaction.save!
          revoke_transactions if should_revoke?
          event.process! if event.present?
          process_transaction
        rescue
          errors.add(:base, :employee_blank, message: 'Something went wrong')
        end
      end
    end

    emp_transaction.errors.blank?
  end

  private

  def process_transaction
    TransactionProcesser.new(emp_transaction).call
  end

  def should_revoke?
    emp_sec_profiles? && transactions_to_revoke?
  end

  def emp_sec_profiles?
    emp_transaction.emp_sec_profiles.count.positive?
  end

  def transactions_to_revoke?
    emp_transaction.revoked_emp_sec_profiles.count.positive?
  end

  def revoke_transactions
    emp_transaction.revoked_emp_sec_profiles.update_all(revoking_transaction_id: @emp_transaction.id)
  end

  def new_worker
    profile_builder.new_employee(event)
  end

  def event
    @event ||= AdpEvent.find(event_id) if event_id.present?
  end

  def needs_new_account?
    link_email == 'off'
  end

  def profile_builder
    @profile_builder ||= EmployeeProfile.new
  end

  def worker
    Employee.find(employee_id)
  end

  def employee_not_found
    errors.add(:base, :employee_blank, message: 'Employee cannot be blank. Please revisit email link to refresh page.')
  end

  def build_transaction_data
    case kind
    when 'Onboarding'
      prepare_onboard
    when 'Security Access'
      build_security_profiles
    when 'Offboarding'
      build_offboard
    when 'Equipment'
      build_machine_bundles
    end
  end

  def prepare_onboard
    build_onboard
    build_security_profiles
    build_machine_bundles
  end

  def link_worker
    profile_builder.link_accounts(linked_account_id, event_id)
  end

  def link_accounts?
    link_email == 'on' && linked_account_id.present?
  end
end
