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
  attribute :termination_date, DateTime
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
  attribute :start_date, DateTime
  attribute :end_date, DateTime

  def link_accounts(employee_id, event_id)
    employee = Employee.find employee_id
    event = AdpEvent.find event_id
    w_hash = parse_event(event.json)

    employee = update_employee(employee, w_hash)

    # employee_attrs, profile_attrs = w_hash.partition{ |k,v| Employee.column_names.include?(k.to_s) }
    # employee.assign_attributes(employee_attrs.to_h)
    # last_profile.assign_attributes(profile_attrs.to_h)

    # delta = build_emp_delta(last_profile)

    # if last_profile.changed?
    #   last_profile.profile_status = "Expired"
    #   last_profile.end_date = Date.today
    #   new_profile = employee.profiles.build(profile_attrs.to_h)

    #   if last_profile.save! and new_profile.save!
    #     puts "saved"
    #   else
    #     puts "didn't save?"
    #   end
    # end

    # if delta.present?
    #   delta.save!
    # end

    # employee.save!
    employee
  end

# EmployeeWorker.perform_async("Security Access", e.id)
#   def send_email?(employee)
#     has_changed = employee.changed? && employee.valid?
#     has_triggering_change = employee.department_id_changed? || employee.location_id_changed? || employee.worker_type_id_changed? || employee.job_title_id_changed?
#     no_previous_changes = employee.emp_deltas.important_changes.blank?

#     if has_changed && has_triggering_change
#       if no_previous_changes
#         true
#       else
#         last_emailed_on = employee.emp_deltas.important_changes.last.created_at
#         if last_emailed_on <= 1.day.ago
#           true
#         end
#       end
#     end
#   end

  def update_employee(employee, employee_hash)
    profile = employee.profiles.active

    employee_attrs, profile_attrs = employee_hash.partition{ |k,v| Employee.column_names.include?(k.to_s) }
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
    employee
  end

  def new_employee(event_json)
    employee = build_employee(event_json)
    employee.status = "Pending"
    employee.save!
    employee
  end

  def parse_event(event)
    json_str = event.json
    event_json = JSON.parse(json_str)
    parser = AdpService::WorkerJsonParser.new
    worker_json = event_json.dig("events", 0, "data", "output", "worker")
    worker_hash = parser.gen_worker_hash(worker_json)
    worker_hash
  end

  def build_employee(event_json)
    worker_hash = parse_event(event_json)
    employee_attrs, profile_attrs = worker_hash.partition{ |k,v| Employee.column_names.include?(k.to_s) }
    employee = Employee.new(employee_attrs.to_h)
    profile = employee.profiles.build(profile_attrs.to_h)
    employee
  end

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

  def save

  end

  def errors
    return @errors ||= {}
  end
end
