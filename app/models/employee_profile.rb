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

  # link accounts takes an employee pk and event pk
  def link_accounts(employee_id, event_id)
    employee = Employee.find employee_id
    event = AdpEvent.find event_id
    w_hash = parse_event(event)

    employee = update_employee(employee, w_hash)
    employee
  end

  # takes employee object and employee hash from the parser
  def update_employee(employee, employee_hash)
    profile = employee.profiles.active

    employee_attrs, profile_attrs = employee_hash.partition{ |k,v| Employee.column_names.include?(k.to_s) }
    employee.assign_attributes(employee_attrs.to_h)
    profile.assign_attributes(profile_attrs.to_h)

    delta = build_emp_delta(profile)

    if profile.changed?
      old_profile = employee.profiles.active
      old_profile.profile_status = "Terminated"
      old_profile.end_date = Date.today
      new_profile = employee.profiles.build(profile_attrs.to_h)
      if old_profile.save! and new_profile.save!
        if send_email?(profile)
          EmployeeWorker.perform_async("Security Access", employee_id: employee.id)
          employee
        end
      end
    end

    if employee.changed?
      employee.save!
    end

    ads = ActiveDirectoryService.new
    ads.update([e])

    if delta.present?
      delta.save!
    end
    employee
  end

  # new employee takes an event object and returns saved employee
  def new_employee(event)
    worker_hash = parse_event(event)
    employee_attrs, profile_attrs = worker_hash.partition{ |k,v| Employee.column_names.include?(k.to_s) }
    employee = Employee.new(employee_attrs.to_h)
    employee.status = "Pending"
    employee.save!
    profile = employee.profiles.build(profile_attrs.to_h)
    profile.save!
    employee
  end

  # takes json attribute from event object and returns unsaved employee
  def build_employee(event)
    worker_hash = parse_event(event)
    employee_attrs, profile_attrs = worker_hash.partition{ |k,v| Employee.column_names.include?(k.to_s) }
    employee = Employee.new(employee_attrs.to_h)
    profile = employee.profiles.build(profile_attrs.to_h)
    employee
  end

  # takes an event object and returns the worker hash
  def parse_event(event)
    json = event.json
    event_json = JSON.parse(json)
    parser = AdpService::WorkerJsonParser.new
    worker_json = event_json.dig("events", 0, "data", "output", "worker")
    worker_hash = parser.gen_worker_hash(worker_json)
    worker_hash
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

  def send_email?(profile)
    has_changed = profile.changed? && profile.valid?
    has_triggering_change = profile.department_id_changed? || profile.location_id_changed? || profile.worker_type_id_changed? || profile.job_title_id_changed?
    no_previous_changes = profile.employee.emp_deltas.important_changes.blank?

    if has_changed && has_triggering_change
      if no_previous_changes
        true
      else
        last_emailed_on = profile.employee.emp_deltas.important_changes.last.created_at
        if last_emailed_on <= 1.day.ago
          true
        end
      end
    end
  end

  def errors
    return @errors ||= {}
  end
end
