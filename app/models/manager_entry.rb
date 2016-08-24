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
      notes: notes
    )
  end

  def build_security_profiles
    security_profile_ids.each do |sp_id|
      emp_transaction.emp_sec_profiles.build(security_profile_id: sp_id, employee_id: employee_id)
    end unless security_profile_ids.blank?
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
    build_security_profiles
    build_machine_bundles
    @emp_transaction.save
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
