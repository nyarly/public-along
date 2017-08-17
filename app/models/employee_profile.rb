class EmployeeProfile
  include Virtus.model

  extend ActiveModel::Naming
  include ActiveModel::Conversion
  include ActiveModel::Validations

  # attributes for employee model
  attribute :status, String
  attribute :first_name, String
  attribute :last_name, String
  attribute :hire_date, DateTime
  attribute :contract_end_date, DateTime
  attribute :office_phone, String
  attribute :personal_mobile_phone, String
  attribute :home_address_1, String
  attribute :home_address_2, String
  attribute :home_city, String
  attribute :home_state, String
  attribute :home_zip, String

  # attributes for profile model
  attribute :adp_assoc_oid, String
  attribute :adp_employee_id, String
  attribute :company, String
  attribute :department_id, Integer
  attribute :job_title_id, Integer
  attribute :location_id, Integer
  attribute :manager_id, String
  attribute :profile_status, String
  attribute :worker_type_id, Integer
  attribute :profile_status, String

  # def initialize(hash)
  #   @employee = employee
  # end

  def process_employee(hash)
    employee = Employee.find_by_employee_id(hash[:adp_employee_id])

    if employee.present?
      profile = employee.profiles.active
      employee_attrs, profile_attrs = hash.partition{ |k,v| Employee.column_names.include?(k.to_s) }
      employee.assign_attributes(employee_attrs.to_h)
      profile.assign_attributes(profile_attrs.to_h)

      delta = build_emp_delta(profile)

      if profile.changed?
        old_profile = employee.profiles.active
        old_profile.profile_status = "Expired"
        old_profile.end_date = Date.today
        new_profile = employee.profiles.build(profile_attrs.to_h)

        if old_profile.save! and new_profile.save!
          puts "saved"
        else
          puts "didn't save?"
        end
      end

      employee.save!
      if delta.present?
        delta.save!
      end
    else
      employee_attrs, profile_attrs = hash.partition{ |k,v| Employee.column_names.include?(k.to_s) }
      employee = Employee.new(employee_attrs.to_h)
      employee.status = "Pending"
      employee.save!

      profile = employee.profiles.build(profile_attrs.to_h)
      employee.save!

    end
    employee
  end

  def new_employee(event_json)
    parser = AdpService::WorkerJsonParser.new
    json = JSON.parse(event_json)
    worker_json = json.dig("events", 0, "data", "output", "worker")
    worker_hash = parser.gen_worker_hash(worker_json)
    puts worker_hash
    employee_attrs, profile_attrs = worker_hash.partition{ |k,v| Employee.column_names.include?(k.to_s) }
    employee = Employee.new(employee_attrs.to_h)
    profile = employee.profiles.build(profile_attrs.to_h)
    employee.status = "Pending"
    employee
  end

  # def new_profile
  #   employee.
  # end

  # def save
  #   ActiveRecord::Base.transaction do

  #   end
  # end

  def build_emp_delta(prof)
    emp_before  = prof.employee.changed_attributes.deep_dup
    emp_after   = Hash[prof.employee.changes.map { |k,v| [k, v[1]] }]
    prof_before = prof.changed_attributes.deep_dup
    prof_after  = Hash[prof.changes.map { |k,v| [k, v[1]] }]
    before      = emp_before.merge!(prof_before)
    after       = emp_after.merge!(prof_after)

    if before.present? and after.present?
      emp_delta = EmpDelta.new(
        employee: prof.employee,
        before: before,
        after: after
      )
    end
    emp_delta
  end


  def errors
    return @errors ||= {}
  end
end
