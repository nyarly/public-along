class AdpService
  attr_accessor :token

  def initialize(env="test")
    @env ||= env
    @domain ||= @env == "prod" ? nil : "uat-"
    @token ||= get_bearer_token
  end

  def populate_job_titles
    str = get_json_str("https://#{@domain}api.adp.com/codelists/hr/v3/worker-management/job-titles/WFN/1")
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
    str = get_json_str("https://#{@domain}api.adp.com/codelists/hr/v3/worker-management/locations/WFN/1")
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
    str = get_json_str("https://#{@domain}api.adp.com/codelists/hr/v3/worker-management/departments/WFN/1")
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

  def populate_workers
    # str = get_json_str("https://#{@domain}api.adp.com/hr/v2/workers?count=true")
    # str = get_json_str("https://#{@domain}api.adp.com/hr/v2/workers?$top=1&$skip=1807")
    # str = get_json_str("https://#{@domain}api.adp.com/hr/v2/workers?$filter=workers/workAssignments/assignmentStatus/statusCode/codeValue%20eq%20%27A%27")
    # str = get_json_str("https://#{@domain}api.adp.com/hr/v2/workers?$filter=workers/workAssignments/reportsTo/positionID%20eq%20%27HR500034N%27")
    # str = get_json_str("https://#{@domain}api.adp.com/hr/v2/workers?$filter=workers/workAssignments/jobCode/codeValueeqXSRMGR")
    # str = get_json_str("https://#{@domain}api.adp.com/hr/v2/workers?$select=workers/workAssignments/assignmentStatus&count=true")
    # str = get_json_str("https://#{@domain}api.adp.com/hr/v2/workers/meta")
    # str = get_json_str("https://#{@domain}api.adp.com/events/hr/v1/worker.business-communication.email.add/meta")
    begin
    ensure
      str = get_json_str("https://#{@domain}api.adp.com/hr/v2/workers?$select=workers/workerStatus&$top=1&count=true")
      json = JSON.parse(str)
      count = json["meta"]["totalNumber"]
    end
    puts api_count: count
    pos = 1700
    workers = []
    while pos <= count
      begin
      ensure
        str = get_json_str("https://#{@domain}api.adp.com/hr/v2/workers?$top=50&$skip=#{pos}")
      end
      json = JSON.parse(str)
      # puts json: json
      json["workers"].each do |w|
        puts w
        status = w["workerStatus"]["statusCode"]["codeValue"]
        unless status == "Terminated"
          adp_assoc_oid = w["associateOID"]
          first_name = w["person"]["legalName"]["nickName"].present? ? w["person"]["legalName"]["nickName"] : w["person"]["legalName"]["givenName"]
          last_name = w["person"]["legalName"]["familyName1"]
          employee_id = w["workerID"]["idValue"]
          work_assignment = w["workAssignments"].find { |wa| wa["primaryIndicator"] == true}
          dept = work_assignment["homeOrganizationalUnits"].find { |ou| ou["typeCode"]["codeValue"] == "Department"}
          biz_unit = work_assignment["homeOrganizationalUnits"].find { |ou| ou["typeCode"]["codeValue"] == "Business Unit"}

          workers << {
            adp_assoc_oid: adp_assoc_oid,
            first_name: first_name,
            last_name: last_name,
            employee_id: employee_id,
            hire_date: work_assignment["hireDate"],
            contract_end_date: work_assignment["terminationDate"],
            termination_date: work_assignment["terminationDate"],
            business_title: find_job_title_id(work_assignment["jobCode"]), #should change db name to job_title_id
            employee_type: find_employee_type(work_assignment), #should later look up worker type object
            manager_id: find_manager_emp_id(work_assignment),
            department_id: find_dept_id(dept),
            location_id: find_location_id(work_assignment["homeWorkLocation"]),
            company: find_biz_unit(biz_unit),
            status: status
            # personal_mobile_phone: ,
            # office_phone: ,
            # home_address_1: ,
            # home_address_2: ,
            # home_city: ,
            # home_state: ,
            # home_zip: ,
            # image_code: ,
            # leave_start_date: ,
            # leave_return_date: ,
          }
        end
      end
      pos+=50
    end
    puts workers: workers
    puts count: workers.count
  end

  def find_biz_unit(json)
    json["nameCode"]["codeValue"] if json
  end

  def find_employee_type(json)
    json["workerTypeCode"]["shortName"] if json["workerTypeCode"]
  end

  def find_manager_emp_id(json)
    json["reportsTo"][0]["workerID"]["idValue"] if json["reportsTo"]
  end


  def find_job_title_id(json)
    if json == nil
      return nil
    else
      code = json["codeValue"]
      jt = JobTitle.find_by(code: code)
      unless jt.present?
        name = json["shortName"].present? ? json["shortName"] : json["longName"]
        jt = JobTitle.create(name: name, code: code, status: "Inactive")
      end
      jt.id
    end
  end

  def find_location_id(json)
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
      loc.id
    end
  end

  def find_dept_id(json)
    if json["nameCode"] == nil
      return nil
    else
      code = json["nameCode"]["codeValue"]
      dept = Department.find_by(code: code)
      unless dept.present?
        name = json["shortName"].present? ? json["shortName"] : json["longName"]
        dept = Department.create({code: code, name: name, status: "Inactive"})
      end
      dept.id
    end
  end

  def meta
    str = get_json_str("https://#{@domain}api.adp.com/hr/v2/workers/meta")
    json = JSON.parse(str)
    puts JSON.pretty_generate(json)
    json
  end

  def list(qty, pos)
    str = get_json_str("https://#{@domain}api.adp.com/hr/v2/workers?$top=#{qty}&$skip=#{pos}&count=true")
    json = JSON.parse(str)
    puts JSON.pretty_generate(json)
    emps = json["workers"]
    puts actual_count: emps.count
    count = json["meta"]["totalNumber"]
    puts worker_count: count
    json
  end

  def worker(uri)
    str = get_json_str("https://#{@domain}api.adp.com/hr/v2/workers#{uri}")
    json = JSON.parse(str)
    puts JSON.pretty_generate(json)
    json
  end

  def events
    str = get_json_str("https://#{@domain}api.adp.com/core/v1/event-notification-messages")
    json = JSON.parse(str)
    puts JSON.pretty_generate(json)
    json
  end

  def del_event(num)
    set_http("https://#{@domain}api.adp.com/core/v1/event-notification-messages#{num}")
    puts @uri.request_uri
    # res = @http.delete(@uri.request_uri, {'Authorization' => "Bearer #{@token}"})
    req = Net::HTTP::Delete.new(@uri.request_uri, {'Authorization' => "Bearer #{@token}"})
    res = @http.request(req)
    puts res: res
  end

  def url(url)
    str = get_json_str("#{url}")
    json = JSON.parse(str)
    puts JSON.pretty_generate(json)
    json
  end

  private

  def creds
    @env == "prod" ? SECRETS.adp_prod_creds : SECRETS.adp_test_creds
  end

  def get_bearer_token
    set_http("https://#{@domain}accounts.adp.com/auth/oauth/v2/token?grant_type=client_credentials")
    res = @http.post(@uri.request_uri,'', {'Accept' => 'application/json', 'Authorization' => "Basic #{creds}"})
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
    puts header: res["adp-msg-msgid"]
    res.body
  end
end
