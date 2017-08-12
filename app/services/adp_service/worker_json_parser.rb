module AdpService
  class WorkerJsonParser

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
      employee_id = w["workerID"]["idValue"].downcase
      personal_mobile_phone = find_mobile(w["person"])
      office_phone = find_office_phone(w["businessCommunication"])

      work_assignment = find_work_assignment(w)

      hire_date = work_assignment["hireDate"]
      worker_end_date = find_worker_end_date(w)

      biz_unit = work_assignment["homeOrganizationalUnits"].find { |ou| ou["typeCode"]["codeValue"] == "Business Unit"}
      company = find_biz_unit(biz_unit)

      job_title = find_job_title(work_assignment["jobCode"])
      worker_type = find_worker_type(work_assignment)

      manager_id = work_assignment.dig("reportsTo",0,"workerID","idValue")
      location = find_location(work_assignment["homeWorkLocation"])
      work_assignment_status = find_work_assignment_status(work_assignment["assignmentStatus"]["statusCode"])

      dept_str = work_assignment["homeOrganizationalUnits"].find { |ou| ou["typeCode"]["codeValue"] == "Department"}
      dept = find_dept(dept_str)

      start_date = work_assignment["actualStartDate"]
      end_date = work_assignment["terminationDate"].present? if work_assignment["terminationDate"].present?

      home_address_1 = w.dig("person","legalAddress","lineOne")
      home_address_2 = w.dig("person","legalAddress","lineTwo")
      home_city = w.dig("person","legalAddress","cityName")
      home_state = w.dig("person","legalAddress","countrySubdivisionLevel1","codeValue")
      home_zip = w.dig("person","legalAddress","postalCode")

      worker = {
        status: status,
        first_name: first_name,
        last_name: last_name,
        hire_date: hire_date,
        contract_end_date: worker_end_date,
        office_phone: office_phone,
        personal_mobile_phone: personal_mobile_phone,
        # image_code: , (eventually)
        start_date: start_date,
        end_date: end_date,
        adp_assoc_oid: adp_assoc_oid,
        adp_employee_id: employee_id,
        company: company,
        department_id: dept.id,
        job_title_id: job_title.id,
        location_id: location.id,
        manager_id: manager_id,
        profile_status: work_assignment_status,
        worker_type_id: worker_type.id,
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

    def find_work_assignment(json)
      if json["workAssignment"].present?
        json["workAssignment"]
      elsif json["workAssignments"].present?
        json["workAssignments"].find { |wa| wa["primaryIndicator"] == true}
      end
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

    def find_work_assignment_status(json)
      if json.present?
        name = json["shortName"].present? ? json["shortName"] : json["codeValue"]
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

    def find_worker_end_date(json)
      custom_dates = json.dig("customFieldGroup","dateFields")
      if custom_dates
        w_end_date_json = custom_dates.find { |f| f["nameCode"]["codeValue"] == "Worker End Date"}
        worker_end_date = w_end_date_json.try(:dig, "dateValue")
      end
      worker_end_date
    end
  end
end
