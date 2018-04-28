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
      adp_status = w["workerStatus"]["statusCode"]["codeValue"]
      adp_assoc_oid = w["associateOID"]
      adp_employee_id = w["workerID"]["idValue"].downcase
      legal_first_name = w["person"]["legalName"]["givenName"]
      first_name = w["person"]["legalName"]["nickName"].present? ? w["person"]["legalName"]["nickName"] : w["person"]["legalName"]["givenName"]
      last_name = find_last_name(w)
      personal_mobile_phone = find_mobile(w["person"])
      office_phone = find_office_phone(w["businessCommunication"])

      hire_date = w["workerDates"]["originalHireDate"]
      rehire_date = w["workerDates"]["rehireDate"].present? ? w["workerDates"]["rehireDate"] : nil
      worker_end_date = find_worker_end_date(w)

      work_assignment = find_work_assignment(w)
      start_date = work_assignment["actualStartDate"].present? ? work_assignment["actualStartDate"] : hire_date
      end_date = work_assignment["terminationDate"].present? if work_assignment["terminationDate"].present?

      biz_unit = work_assignment["homeOrganizationalUnits"].find { |ou| ou["typeCode"]["codeValue"] == "Business Unit"}
      company = find_biz_unit(biz_unit)

      job_title = find_job_title(work_assignment["jobCode"])
      business_card_title = business_card_title(w).present? ? business_card_title(w) : job_title.name
      worker_type = find_worker_type(work_assignment)

      manager_adp_employee_id = work_assignment.dig("reportsTo",0,"workerID","idValue")
      manager_id = find_manager(manager_adp_employee_id)
      location = find_location(work_assignment["homeWorkLocation"])
      work_assignment_status = find_work_assignment_status(work_assignment["assignmentStatus"]["statusCode"])

      dept_str = work_assignment["homeOrganizationalUnits"].find { |ou| ou["typeCode"]["codeValue"] == "Department"}
      dept = find_dept(dept_str)

      management_position = work_assignment["managementPositionIndicator"]
      payroll_file_number = work_assignment["payrollFileNumber"]

      line_1 = w.dig("person","legalAddress","lineOne")
      line_2 = w.dig("person","legalAddress","lineTwo")
      city = w.dig("person","legalAddress","cityName")
      state_territory = w.dig("person","legalAddress","countrySubdivisionLevel1","codeValue")
      postal_code = w.dig("person","legalAddress","postalCode")
      country_code = w.dig("person","legalAddress","countryCode")
      country_id = find_country(country_code)

      worker = {
        adp_status: adp_status,
        legal_first_name: legal_first_name,
        first_name: first_name,
        last_name: last_name,
        hire_date: hire_date,
        rehire_date: rehire_date,
        contract_end_date: worker_end_date,
        office_phone: office_phone,
        personal_mobile_phone: personal_mobile_phone,
        # image_code: , (eventually)
        start_date: start_date,
        end_date: end_date,
        adp_assoc_oid: adp_assoc_oid,
        adp_employee_id: adp_employee_id,
        company: company,
        department_id: dept.id,
        job_title_id: job_title.id,
        location_id: location.id,
        manager_id: manager_id,
        manager_adp_employee_id: manager_adp_employee_id,
        profile_status: work_assignment_status.downcase!,
        worker_type_id: worker_type.id,
        business_card_title: business_card_title,
        management_position: management_position,
        payroll_file_number: payroll_file_number
      }

      if location.kind == "Remote Location"
        contact_info = {
          line_1: line_1,
          line_2: line_2,
          city: city,
          state_territory: state_territory,
          postal_code: postal_code,
          country_id: country_id
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
        pref_name.strip
      else
        json.dig("person","legalName","familyName1").strip
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

    def business_card_title(json)
      custom_strings = json.dig("customFieldGroup", "stringFields")
      if custom_strings
        business_card_title_json = custom_strings.find { |f| f["nameCode"]["codeValue"] == "Business Card Title" }
        business_card_title = business_card_title_json.try(:dig, "stringValue")
      end
      business_card_title
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

    def find_manager(manager_adp_employee_id)
      return nil if manager_adp_employee_id.blank?
      manager = Employee.find_by_employee_id(manager_adp_employee_id)
      return nil if manager.blank?
      manager.id
    end

    def find_country(country_code)
      return nil if country_code.blank?
      country = Country.find_by(iso_alpha_2: country_code)
      return nil if country.blank?
      country.id
    end
  end
end
