class AdpService
  attr_accessor :token

  def initialize
    @token ||= get_bearer_token
  end

  def populate_job_titles
    str = get_json_str("https://uat-api.adp.com/codelists/hr/v3/worker-management/job-titles/WFN/1")
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
    str = get_json_str("https://uat-api.adp.com/codelists/hr/v3/worker-management/locations/WFN/1")
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
        Location.create({code: code, name: name, status: "Active", country: "Pending Assignment", kind: "Pending Assignment", timezone: "Pending Assignment"})
      end
    end
    #TODO (Netops-763) gather all new locations and send email to P&C notifying them that these location attributes need to be assigned.
  end

  def populate_departments
    str = get_json_str("https://uat-api.adp.com/codelists/hr/v3/worker-management/departments/WFN/1")
    json = JSON.parse(str)
    depts = json["codeLists"].find { |d| d["codeListTitle"] == "departments"}["listItems"]
    depts.each do |d|
      code = d["codeValue"]
      name = d["shortName"].present? ? d["shortName"] : d["longName"]
      dept = Department.find_or_create_by(code: code)
      dept.update_attributes({name: name})
    end
    #TODO (Netops-763) gather all depts without parent orgs and send email to P&C notifying them that these attributes need to be assigned.
  end

  def populate_employees
    # str = get_json_str("https://uat-api.adp.com/hr/v2/workers?count=true")
    # str = get_json_str("https://uat-api.adp.com/hr/v2/workers?$top=1&$skip=1807")
    # str = get_json_str("https://uat-api.adp.com/hr/v2/workers?$filter=workers/workAssignments/assignmentStatus/statusCode/codeValue%20eq%20%27A%27")
    # str = get_json_str("https://uat-api.adp.com/hr/v2/workers?$filter=workers/workAssignments/reportsTo/positionID%20eq%20%27HR500034N%27")
    # str = get_json_str("https://uat-api.adp.com/hr/v2/workers?$filter=workers/workAssignments/jobCode/codeValueeqXSRMGR")
    # str = get_json_str("https://uat-api.adp.com/hr/v2/workers?$select=workers/workAssignments/assignmentStatus&count=true")
    # str = get_json_str("https://uat-api.adp.com/hr/v2/workers/meta")
    # str = get_json_str("https://uat-api.adp.com/events/hr/v1/worker.business-communication.email.add/meta")
    pos = 0
    count = 1
    active = 0
    leave = 0
    termed =0
    inactive =0
    unknown = []
    employees = []
    while pos <= count
      puts pos: "#{Time.now} GETTING position #{pos}"
      begin
      ensure
        # str = get_json_str("https://uat-api.adp.com/hr/v2/workers?$select=workers/workerStatus&$top=50&$skip=#{pos}&count=true")
        str = get_json_str("https://uat-api.adp.com/hr/v2/workers?$select=workers/workAssignments&$top=50&$skip=#{pos}&count=true")
      end
      json = JSON.parse(str)
      count = json["meta"]["totalNumber"]
      workers = json["workers"].each do |w|
        "email"
        "first_name"
        "last_name"
        "employee_id"
        "hire_date"
        "contract_end_date"
        "termination_date"
        "business_title"
        "employee_type"
        "manager_id"
        "personal_mobile_phone"
        "office_phone"
        "home_address_1"
        "home_address_2"
        "home_city"
        "home_state"
        "home_zip"
        "image_code"
        "leave_start_date"
        "leave_return_date"
        "department_id"
        "location_id"
        "company"
        "status"
        id = w["workerID"]["idValue"]
        name = w["person"]["legalName"]["formattedName"]
        status = w["workerStatus"]["statusCode"]["codeValue"]
        employees << {id: id, name: name, status: status}
        if status == "Active"
          active +=1
        elsif status == "Leave"
          leave +=1
        elsif status == "Terminated"
          termed +=1
        elsif status == "Inactive"
          inactive +=1
        elsif status.blank?
          unknown << "empty"
        else
          unknown << status
        end
      end

      pos += 50
      puts active: active
      puts leave: leave
      puts termed: termed
      puts inactive: inactive
      puts unknown: unknown
    end
    puts "FINAL NUMBERS"
    puts totalCount: count
    puts active: active
    puts leave: leave
    puts termed: termed
    puts inactive: inactive
    puts unknown: unknown
    return employees
    # depts = json["codeLists"].find { |d| d["codeListTitle"] == "departments"}["listItems"]
    # depts.each do |d|
    #   code = d["codeValue"]
    #   name = d["shortName"].present? ? d["shortName"] : d["longName"]
    #   dept = Department.find_or_create_by(code: code)
    #   dept.update_attributes({name: name})
    # end
    #TODO (Netops-763) gather all depts without parent orgs and send email to P&C notifying them that these attributes need to be assigned.
  end

  def meta
    str = get_json_str("https://uat-api.adp.com/hr/v2/workers/meta")
    json = JSON.parse(str)
    puts JSON.pretty_generate(json)
    json
  end

  def list(qty, pos)
    str = get_json_str("https://uat-api.adp.com/hr/v2/workers?$top=#{qty}&$skip=#{pos}&count=true")
    json = JSON.parse(str)
    puts JSON.pretty_generate(json)
    emps = json["workers"]
    puts actual_count: emps.count
    count = json["meta"]["totalNumber"]
    puts worker_count: count
    json
  end

  def worker(uri)
    str = get_json_str("https://uat-api.adp.com/hr/v2/workers#{uri}")
    json = JSON.parse(str)
    puts JSON.pretty_generate(json)
    json
  end

  def events
    str = get_json_str("https://uat-api.adp.com/core/v1/event-notification-messages")
    json = JSON.parse(str)
    puts JSON.pretty_generate(json)
    json
  end

  def url(url)
    str = get_json_str("#{url}")
    json = JSON.parse(str)
    puts JSON.pretty_generate(json)
    json
  end

  private

  def get_bearer_token
    set_http("https://uat-accounts.adp.com/auth/oauth/v2/token?grant_type=client_credentials")
    res = @http.post(@uri.request_uri,'', {'Accept' => 'application/json', 'Authorization' => "Basic #{SECRETS.adp_creds}"})
    JSON.parse(res.body)["access_token"]
  end

  def set_http(url)
    @uri = URI.parse(url)
    @http = Net::HTTP.new(@uri.host, @uri.port)
    @http.use_ssl = true
    @http.verify_mode = OpenSSL::SSL::VERIFY_PEER
    @http.cert = OpenSSL::X509::Certificate.new(SECRETS.adp_pem)
    @http.key = OpenSSL::PKey::RSA.new(SECRETS.adp_key)
  end

  def get_json_str(url)
    set_http(url)
    res = @http.get(@uri.request_uri, {'Accept' => 'application/json', 'Authorization' => "Bearer #{@token}"})
    puts "#{Time.now} Response received"
    puts res
    res.body
  end
end
