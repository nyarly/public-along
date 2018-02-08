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

  # attributes for address model
  attribute :line_1, String
  attribute :line_2, String
  attribute :line_3, String
  attribute :city, String
  attribute :state_territory, String
  attribute :postal_code, String
  attribute :country_id, Integer

  # link accounts takes an employee pk and event pk
  def link_accounts(employee_id, event_id)
    worker_hash = event_worker_hash(event_id)

    employee = Employee.find(employee_id).tap do |employee|
      build_new_profile(employee, worker_hash).save!

      # never update hire date for rehires/conversions
      worker_hash.except!(:hire_date) if employee.terminated?
      # don't update employee info on workers who are converting
      assign_employee_attributes(employee, worker_hash) unless employee.active?

      employee.termination_date = nil
      employee.save!
    end
  end

  # takes employee object and employee hash from the parser
  def update_employee(employee, employee_hash)
    employee_hash.except!(:contract_end_date) if contingent_worker_rehire?(employee_hash) || policy(employee).is_conversion?
    assign_employee_attributes(employee, employee_hash)

    profile = employee.current_profile
    profile.assign_attributes(parse_attributes(Profile, employee_hash))

    handle_address(employee, employee_hash) if address_hash?(employee_hash)

    delta = EmpDelta.build_from_profile(profile)

    # create new profile for changes to worker type or ADP record
    if needs_new_profile?(profile)
      # reload profile object to discard changes
      profile.reload
      new_profile_for_existing_worker(employee, employee_hash)
    end

    if delta.present?
      delta.save!
      EmployeeService::ChangeHandler.new(employee).call
    end

    employee.save! && profile.save!
  end

  # new employee takes an event object and returns saved employee
  def new_employee(event)
    worker_hash = parse_event(event)
    employee = Employee.new(parse_attributes(Employee, worker_hash).except(:status)).tap do |employee|
      employee.save!
      profile = build_new_profile(employee, worker_hash)
      profile.profile_status = "pending"
      profile.save!
      address = build_new_address(employee, worker_hash)
      address.save!
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

  def address_hash?(worker_hash)
    worker_hash[:line_1].present?
  end

  def handle_address(employee, worker_hash)
    address = employee.address
    if address.present?
      address.assign_attributes(parse_attributes(Address, employee_hash))
      address.save!
    else
      new_address = build_new_address(employee, employee_hash)
      new_address.save!
    end
  end

  def build_new_address(employee, worker_hash)
    employee.addresses.build(parse_attributes(Address, worker_hash))
  end

  def policy(employee)
    EmployeePolicy.new(employee)
  end

  def build_new_profile(employee, employee_hash)
    employee.profiles.build(parse_attributes(Profile, employee_hash))
  end

  def assign_employee_attributes(employee, employee_hash)
    employee.assign_attributes(parse_attributes(Employee, employee_hash))
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

  # Rehires may include old contract end date that no longer applies
  def contingent_worker_rehire?(emp_hash)
    if emp_hash[:contract_end_date].present? && emp_hash[:rehire_date].present?
      return emp_hash[:contract_end_date] <= emp_hash[:rehire_date]
    end
    false
  end

  def needs_new_profile?(profile)
    profile.worker_type_id_changed? || profile.adp_employee_id_changed?
  end

  def rehire_or_conversion_hash(w_hash)
    future_status = [:profile_status, :status]
    w_hash.except!(*future_status)
    w_hash.except!(:contract_end_date) if contingent_worker_rehire?(w_hash)
    w_hash
  end

  def event_worker_hash(event_id)
    worker_hash = parse_event(worker_event(event_id))
    rehire_or_conversion_hash(worker_hash)
  end

  def worker_event(event_id)
    AdpEvent.find(event_id)
  end

  def new_profile_for_existing_worker(employee, employee_hash)
    profile = Profile.find(employee.current_profile.id)

    new_profile = build_new_profile(employee, employee_hash)

    if new_profile.start_date > Date.today
      new_profile.profile_status = "pending"
    else
      profile.profile_status = "terminated"
      profile.end_date = Date.today
      new_profile.profile_status = "active"
    end

    profile.save! && new_profile.save!
    new_profile
  end
end
