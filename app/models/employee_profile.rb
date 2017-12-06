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
  attribute :business_card_title, String
  attribute :manager_id, Integer

  # attributes for profile model
  attribute :adp_assoc_oid, String
  attribute :adp_employee_id, String
  attribute :company, String
  attribute :department_id, Integer
  attribute :job_title_id, Integer
  attribute :location_id, Integer
  attribute :profile_status, String
  attribute :worker_type_id, Integer
  attribute :profile_status, String
  attribute :start_date, DateTime
  attribute :end_date, DateTime
  attribute :management_position, Boolean
  attribute :manager_adp_employee_id, String

  # link accounts takes an employee pk and event pk
  def link_accounts(employee_id, event_id)
    w_hash = parse_event(AdpEvent.find(event_id))

    employee = Employee.find(employee_id).tap do |employee|
      w_hash.except!(:contract_end_date) if discard_contract_end_date?(w_hash)

      employee.assign_attributes(parse_attributes(Employee, w_hash.except(:status)))
      employee.assign_attributes(termination_date: nil)
      new_profile = build_new_profile(employee, w_hash.except(:profile_status))

      EmpDelta.build_from_profile(new_profile).save!

      new_profile.save!
      employee.save!
    end
  end

  # takes employee object and employee hash from the parser
  def update_employee(employee, employee_hash)
    profile = employee.current_profile

    employee_hash.except!(:contract_end_date) if discard_contract_end_date?(employee_hash)

    employee.assign_attributes(parse_attributes(Employee, employee_hash))
    profile.assign_attributes(parse_attributes(Profile, employee_hash))

    delta = EmpDelta.build_from_profile(profile)

    # create new profile for changes to worker type or ADP record
    if needs_new_profile?(profile)
      # reload profile object to discard changes
      profile = Profile.find(employee.current_profile.id)
      profile.reload

      new_profile = build_new_profile(employee, employee_hash)

      if new_profile.start_date > Date.today
        new_profile.profile_status = "pending"
      else
        profile.profile_status = "terminated"
        new_profile.profile_status = "active"
      end

      new_profile.save!
    end

    if delta.present?
      delta.save!
      EmployeeService::ChangeHandler.new(employee).call
    end

    profile.save! && employee.save!
  end

  # new employee takes an event object and returns saved employee
  def new_employee(event)
    worker_hash = parse_event(event)
    employee = Employee.new(parse_attributes(Employee, worker_hash).except(:status)).tap do |employee|
      employee.save!
      profile = build_new_profile(employee, worker_hash)
      profile.profile_status = "pending"
      profile.save!
    end
  end

  # takes json attribute from event object and returns unsaved employee
  def build_employee(event)
    worker_hash = parse_event(event)
    employee = Employee.new(parse_attributes(Employee, worker_hash)).tap do |employee|
      build_new_profile(employee, worker_hash)
    end
  end

  private

  def build_new_profile(employee, employee_hash)
    employee.profiles.build(parse_attributes(Profile, employee_hash))
  end

  def parse_attributes(klass, worker_hash)
    class_attrs, discard = worker_hash.partition{ |k, v| klass.column_names.include?(k.to_s) }
    class_attrs.to_h
  end

  # takes an event object and returns the worker hash
  def parse_event(event)
    data = event.json
    json = JSON.parse(data)
    worker_json = json.dig("events", 0, "data", "output", "worker")
    parser = AdpService::WorkerJsonParser.new
    parser.gen_worker_hash(worker_json)
  end

  def discard_contract_end_date?(emp_hash)
    return false if emp_hash[:contract_end_date].blank?
    return false if emp_hash[:rehire_date].blank?
    emp_hash[:contract_end_date] < emp_hash[:rehire_date]
  end

  def needs_new_profile?(profile)
    profile.worker_type_id_changed? || profile.adp_employee_id_changed?
  end
end
