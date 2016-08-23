# Form Model

class ManagerEntry
  include Virtus.model

  extend ActiveModel::Naming
  include ActiveModel::Conversion
  include ActiveModel::Validations

  attribute :kind, String
  attribute :employee_id, Integer
  attribute :user_id, Integer
  attribute :security_profile_ids, Array[Integer]
  attribute :machine_bundles, Array[MachineBundle]
  attribute :notes, String

  # attr_writer emp_transaction
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
    puts "up here"
    security_profile_ids.each do |sp_id|
      puts "here"
      puts @emp_transaction.inspect
      @emp_transaction.emp_sec_profiles.build(security_profile_id: sp_id, employee_id: employee_id)
      puts :emp_sec_profiles => @emp_transaction.emp_sec_profiles.last.inspect
      # sp = SecurityProfile.find sp_id
      # @@emp_transaction.security_profiles << sp
    end
    # puts @@emp_transaction.emp_sec_profiles.all
  end

  def save
    build_security_profiles
    @emp_transaction.save
    unless @emp_transaction.errors.blank?
      @errors = @emp_transaction.errors
    end
    errors.blank?
  end

end
