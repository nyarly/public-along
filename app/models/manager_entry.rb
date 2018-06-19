# Responsible for handling manager forms
class ManagerEntry
  include Virtus.model

  extend ActiveModel::Naming
  include ActiveModel::Conversion
  include ActiveModel::Validations
  include ActiveModel::Model

  attr_reader :emp_transaction
  attr_reader :employee
  attr_reader :form_inst
  attr_reader :form_klass
  attr_reader :user

  attribute :reason, String
  attribute :token, String

  attribute :kind, String
  attribute :employee_id, Integer
  attribute :user_id, Integer
  attribute :notes, String

  attribute :machine_bundle_id, Integer
  attribute :security_profile_ids, Array[Integer]

  def initialize(params)
    self.extend(Virtus.model)

    @form_klass = EmpTransaction::FORMS.fetch(params[:kind])

    raise 'Invalid form' if form_klass.nil?

    form_klass.attribute_set.each do |a|
      self.attribute(a.name, a.primitive, lazy: true)
    end

    params.each do |key, value|
      instance_variable_set("@#{key}", value)
    end

    @form_inst = form_klass.new(params)
  end

  def emp_transaction
    @emp_transaction ||= employee.emp_transactions.build(
      kind: kind,
      user_id: user_id,
      notes: notes,
    )
  end

  def employee
    return form_inst.employee if employee_id.blank? && (form_klass.instance_methods(false).include? :employee)
    @employee ||= Employee.find(employee_id)
    form_inst.employee = @employee
  end

  def event
    form_inst.event if (form_inst.respond_to? :event_id) && (form_klass.instance_methods(false).include? :event)
  end

  def errors
    @errors ||= ActiveModel::Errors.new(self)
  end

  def user
    @user ||= User.find(user_id)
  end

  def security_profiles
    old_profile_ids = employee.active_security_profiles.present? ? employee.active_security_profiles.pluck(:id).map(&:to_i) : []
    new_profile_ids = security_profile_ids.present? ? security_profile_ids.map(&:to_i) : []

    add_profile_ids = new_profile_ids - old_profile_ids
    revoke_profile_ids = old_profile_ids - new_profile_ids

    revoke_profile_ids.each do |sp_id|
      esp_to_revoke = employee.emp_sec_profiles.where('security_profile_id = ? AND revoking_transaction_id IS NULL', sp_id).last
      emp_transaction.revoked_emp_sec_profiles << esp_to_revoke
    end unless revoke_profile_ids.blank?

    add_profile_ids.each do |sp_id|
      emp_transaction.emp_sec_profiles.build(security_profile_id: sp_id)
    end unless add_profile_ids.blank?
  end

  def machine_bundle
    machine_bundle = MachineBundle.find(machine_bundle_id)
    emp_transaction.emp_mach_bundles.build(
      machine_bundle_id: machine_bundle_id,
      details: { machine_bundle.name.to_sym => machine_bundle.description }
    )
  end

  def machine_bundles
    if employee.worker_type.kind == 'Regular'
      MachineBundle.find_bundles_for(employee.department.id) - MachineBundle.contingent_bundles
    else
      MachineBundle.contingent_bundles
    end
  end

  def save
    ActiveRecord::Base.transaction do
      employee.save! if employee_id.blank?

      machine_bundle if machine_bundle_id.present?
      security_profiles if security_profile_changes?
      employee.emp_transactions << emp_transaction

      revoke_transactions if should_revoke?

      form_inst.emp_transaction = emp_transaction
      form_inst.save
      TransactionProcesser.new(emp_transaction).call
    end
  end

  private

  def security_profile_changes?
    kind == 'onboarding' || kind == 'job_change' || kind == 'security_access'
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
end
