class AdpService
  attr_accessor :token

  def initialize
    @token ||= get_bearer_token
  end

  def populate_job_titles
    str = get_json_str("https://#{SECRETS.adp_api_domain}/codelists/hr/v3/worker-management/job-titles/WFN/1")
    json = JSON.parse(str)
    titles = json["codeLists"].find { |l| l["codeListTitle"] == "job-titles"}["listItems"]
    JobTitle.update_all(status: "Inactive")
    titles.each do |t|
      code = t["codeValue"]
      name = t["shortName"].present? ? t["shortName"] : t["longName"]
      jt = JobTitle.find_or_create_by(code: code)
      jt.update_attributes({name: name, status: "Active"})
    end
  end

  def populate_locations
    str = get_json_str("https://#{SECRETS.adp_api_domain}/codelists/hr/v3/worker-management/locations/WFN/1")
    json = JSON.parse(str)
    locs = json["codeLists"].find { |l| l["codeListTitle"] == "locations"}["listItems"]
    Location.update_all(status: "Inactive")
    locs.each do |l|
      code = l["codeValue"]
      name = l["shortName"].present? ? l["shortName"] : l["longName"]
      loc = Location.find_by(code: code)
      if loc.present?
        loc.update_attributes({name: name, status: "Active"})
      else
        Location.create({code: code, name: name, status: "Active"})
      end
    end
    #TODO (Netops-763) gather all new locations and send email to P&C notifying them that these location attributes need to be assigned.
  end

  def populate_departments
    str = get_json_str("https://#{SECRETS.adp_api_domain}/codelists/hr/v3/worker-management/departments/WFN/1")
    json = JSON.parse(str)
    depts = json["codeLists"].find { |d| d["codeListTitle"] == "departments"}["listItems"]
    Department.update_all(status: "Inactive")
    depts.each do |d|
      code = d["codeValue"]
      name = d["shortName"].present? ? d["shortName"] : d["longName"]
      dept = Department.find_or_create_by(code: code)
      dept.update_attributes({name: name, status: "Active"})
    end
    #TODO (Netops-763) gather all depts without parent orgs and send email to P&C notifying them that these attributes need to be assigned.
  end

  def populate_worker_types
    str = get_json_str("https://#{SECRETS.adp_api_domain}/hr/v2/workers/meta")
    json = JSON.parse(str)
    w_types = json["meta"]["/workers/workAssignments/workerTypeCode"]["codeList"]["listItems"]
    WorkerType.update_all(status: "Inactive")
    w_types.each do |wt|
      code = wt["codeValue"]
      name = wt["shortName"].present? ? wt["shortName"] : wt["longName"]
      w_type = WorkerType.find_by(code: code)
      if w_type.present?
        w_type.update_attributes({name: name, status: "Active"})
      else
        WorkerType.create({code: code, name: name, status: "Active", kind: "Pending Assignment"})
      end
    end
    #TODO (Netops-763) gather all worker types without :kind attr and send email to P&C notifying them that these attributes need to be assigned.
  end

  def populate_workers(url)
    begin
    ensure
      str = get_json_str(url)
    end

    unless str == nil
      json = JSON.parse(str)

      workers = sort_workers(json)

      workers.each do |w|
        e = Employee.find_or_create_by(employee_id: w[:employee_id])
        e.update_attributes(w) if e
      end
    end
  end

  def worker_count
    begin
    ensure
      str = get_json_str("https://#{SECRETS.adp_api_domain}/hr/v2/workers?$select=workers/workerStatus&$top=1&count=true")
      json = JSON.parse(str)
      count = json["meta"]["totalNumber"]
    end
    count
  end

  def create_worker_urls
    count = worker_count
    pos = 0
    urls = []
    while pos <= count
      urls << "https://#{SECRETS.adp_api_domain}/hr/v2/workers?$top=25&$skip=#{pos}"
      pos += 25
    end
    urls
  end

  def create_sidekiq_workers
    create_worker_urls.each do |url|
      AdpWorker.perform_async(url)
    end
  end

  def sort_workers(json)
    workers = []

    json["workers"].each do |w|
      status = w.dig("workerStatus","statusCode","codeValue")
      if status == "Active" || status == "Inactive"
        workers << gen_worker_hash(w)
      end
    end

    workers
  end

  def gen_worker_hash(w)
    status = w["workerStatus"]["statusCode"]["codeValue"]
    adp_assoc_oid = w["associateOID"]
    first_name = w["person"]["legalName"]["nickName"].present? ? w["person"]["legalName"]["nickName"] : w["person"]["legalName"]["givenName"]
    last_name = find_last_name(w)
    employee_id = w["workerID"]["idValue"]
    personal_mobile_phone = find_mobile(w["person"])
    office_phone = find_office_phone(w["businessCommunication"])

    work_assignment = w["workAssignments"].find { |wa| wa["primaryIndicator"] == true}

    hire_date = work_assignment["hireDate"]
    custom_dates = w.dig("customFieldGroup","dateFields")
    if custom_dates
      w_end_date_json = custom_dates.find { |f| f["nameCode"]["codeValue"] == "Worker End Date"}
      worker_end_date = w_end_date_json.try(:dig, "dateValue")
    end
    termination_date = work_assignment["terminationDate"]

    biz_unit = work_assignment["homeOrganizationalUnits"].find { |ou| ou["typeCode"]["codeValue"] == "Business Unit"}
    company = find_biz_unit(biz_unit)

    job_title = find_job_title(work_assignment["jobCode"])
    worker_type = find_worker_type(work_assignment)
    manager_id = work_assignment.dig("reportsTo",0,"workerID","idValue")
    location = find_location(work_assignment["homeWorkLocation"])

    dept_str = work_assignment["homeOrganizationalUnits"].find { |ou| ou["typeCode"]["codeValue"] == "Department"}
    dept = find_dept(dept_str)

    home_address_1 = w.dig("person","legalAddress","lineOne")
    home_address_2 = w.dig("person","legalAddress","lineTwo")
    home_city = w.dig("person","legalAddress","cityName")
    home_state = w.dig("person","legalAddress","countrySubdivisionLevel1","codeValue")
    home_zip = w.dig("person","legalAddress","postalCode")

    worker = {
      status: status,
      adp_assoc_oid: adp_assoc_oid,
      first_name: first_name,
      last_name: last_name,
      employee_id: employee_id,
      hire_date: hire_date,
      contract_end_date: worker_end_date,
      termination_date: termination_date,
      company: company,
      job_title_id: job_title.id,
      worker_type_id: worker_type.id,
      manager_id: manager_id,
      department_id: dept.id,
      location_id: location.id,
      office_phone: office_phone,
      personal_mobile_phone: personal_mobile_phone,
      # image_code: , (eventually)
    }

    if location.kind == "Remote Location"
      contact_info = {
        home_address_1: home_address_1,
        home_address_2: home_address_2,
        home_city: home_city,
        home_state: home_state,
        home_zip: home_zip,
      }

      worker.merge!(contact_info)
    end
    worker
  end

  def find_last_name(json)
    custom = json.dig("person", "customFieldGroup", "stringFields")
    if custom
      pref_blob = custom.find {|field| field["nameCode"]["codeValue"] == "Preferred Last Name"}
      pref_name = pref_blob.try(:dig, "stringValue")
    end
    if pref_name.present?
      pref_name
    else
      json.dig("person","legalName","familyName1")
    end
  end

  def find_office_phone(json)
    if json.try(:dig, "mobiles")
      num = json["mobiles"][0]["formattedNumber"]
    elsif json.try(:dig, "landlines")
      num = json["landlines"][0]["formattedNumber"]
    else
      num = nil
    end
    num
  end

  def find_mobile(json)
    if json.dig("communication","mobiles").present?
      num_json = json.dig("communication","mobiles").find { |num| num["nameCode"]["codeValue"] == "Personal Cell"}
      num = num_json["formattedNumber"] if num_json
      num
    end
  end

  def find_biz_unit(json)
    if json
      biz_unit = json["nameCode"]
      biz_unit["shortName"].present? ? biz_unit["shortName"] : biz_unit["longName"]
    end
  end

  def find_worker_type(json)
    code = json.dig("workerTypeCode","codeValue")
    wt = WorkerType.find_by(code: code)
    wt
  end


  def find_job_title(json)
    if json == nil
      return nil
    else
      code = json["codeValue"]
      jt = JobTitle.find_by(code: code)
      unless jt.present?
        name = json["shortName"].present? ? json["shortName"] : json["longName"]
        jt = JobTitle.create(name: name, code: code, status: "Inactive")
      end
      jt
    end
  end

  def find_location(json)
    if json == nil
      return nil
    else
      json = json["nameCode"]
      code = json["codeValue"]
      loc = Location.find_by(code: code)
      unless loc.present?
        name = json["shortName"].present? ? json["shortName"] : json["longName"]
        loc = Location.create({code: code, name: name, status: "Inactive"})
      end
      loc
    end
  end

  def find_dept(json)
    if json.try(:dig, "nameCode") == nil
      return Department.find_or_create_by(name: "No Department Found", code: "XXXXXXX")
    else
      code = json["nameCode"]["codeValue"]
      dept = Department.find_by(code: code)
      unless dept.present?
        name = json["nameCode"]["shortName"].present? ? json["nameCode"]["shortName"] : json["nameCode"]["longName"]
        dept = Department.create({code: code, name: name, status: "Inactive"})
      end
      dept
    end
  end

  def meta
    str = get_json_str("https://#{SECRETS.adp_api_domain}/hr/v2/workers/meta")
    json = JSON.parse(str)
    puts JSON.pretty_generate(json)
    json
  end

  def list(qty, pos)
    str = get_json_str("https://#{SECRETS.adp_api_domain}/hr/v2/workers?$top=#{qty}&$skip=#{pos}&count=true")
    json = JSON.parse(str)
    puts JSON.pretty_generate(json)
    emps = json["workers"]
    puts actual_count: emps.count
    count = json["meta"]["totalNumber"]
    puts worker_count: count
    json
  end

  def worker(uri)
    str = get_json_str("https://#{SECRETS.adp_api_domain}/hr/v2/workers#{uri}")
    json = JSON.parse(str)
    puts JSON.pretty_generate(json)
    json
  end

  def events
    str = get_json_str("https://#{SECRETS.adp_api_domain}/core/v1/event-notification-messages")
    json = JSON.parse(str)
    puts JSON.pretty_generate(json)
    json
  end

  def del_event(num)
    set_http("https://#{SECRETS.adp_api_domain}/core/v1/event-notification-messages#{num}")
    res = @http.delete(@uri.request_uri, {'Authorization' => "Bearer #{@token}"})
  end

  def url(url)
    str = get_json_str("#{url}")
    json = JSON.parse(str)
    puts JSON.pretty_generate(json)
    json
  end

  private

  def get_bearer_token
    set_http("https://#{SECRETS.adp_token_domain}/auth/oauth/v2/token?grant_type=client_credentials")
    res = @http.post(@uri.request_uri,'', {'Accept' => 'application/json', 'Authorization' => "Basic #{SECRETS.adp_creds}"})

    JSON.parse(res.body)["access_token"]
  end

  def set_http(url)
    @uri = URI.parse(url)
    @http = Net::HTTP.new(@uri.host, @uri.port)
    @http.read_timeout = 200
    @http.use_ssl = true
    @http.verify_mode = OpenSSL::SSL::VERIFY_PEER
    pem = File.read(SECRETS.adp_pem_path)
    key = File.read(SECRETS.adp_key_path)
    @http.cert = OpenSSL::X509::Certificate.new(pem)
    @http.key = OpenSSL::PKey::RSA.new(key)
  end

  def get_json_str(url)
    set_http(url)
    res = @http.get(@uri.request_uri, {'Accept' => 'application/json', 'Authorization' => "Bearer #{@token}"})
    res.body
  end
end
