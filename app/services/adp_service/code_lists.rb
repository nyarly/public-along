module AdpService
  class CodeLists < Base

    def sync_job_titles
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

    def sync_locations
      str = get_json_str("https://#{SECRETS.adp_api_domain}/codelists/hr/v3/worker-management/locations/WFN/1")
      json = JSON.parse(str)
      locs = json["codeLists"].find { |l| l["codeListTitle"] == "locations"}["listItems"]
      Location.update_all(status: "Inactive")
      new_locations = []
      locs.each do |l|
        code = l["codeValue"]
        name = l["shortName"].present? ? l["shortName"] : l["longName"]
        loc = Location.find_by(code: code)
        if loc.present?
          loc.update_attributes({name: name, status: "Active"})
        else
          new_location = Location.create({code: code, name: name, status: "Active"})
          new_locations << new_location
        end
      end
      if new_locations.present?
        PeopleAndCultureMailer.code_list_email(new_locations).deliver_now
      end
      #TODO (Netops-763) gather all new locations and send email to P&C notifying them that these location attributes need to be assigned.
    end

    def sync_departments
      str = get_json_str("https://#{SECRETS.adp_api_domain}/codelists/hr/v3/worker-management/departments/WFN/1")
      json = JSON.parse(str)
      depts = json["codeLists"].find { |d| d["codeListTitle"] == "departments"}["listItems"]
      Department.update_all(status: "Inactive")
      new_departments = []
      depts.each do |d|
        code = d["codeValue"]
        name = d["shortName"].present? ? d["shortName"] : d["longName"]
        dept = Department.find_or_create_by(code: code)
        dept.update_attributes({name: name, status: "Active"})
      end
      #TODO (Netops-763) gather all depts without parent orgs and send email to P&C notifying them that these attributes need to be assigned.
    end

    def sync_worker_types
      str = get_json_str("https://#{SECRETS.adp_api_domain}/hr/v2/workers/meta")
      json = JSON.parse(str)
      w_types = json["meta"]["/workers/workAssignments/workerTypeCode"]["codeList"]["listItems"]
      WorkerType.update_all(status: "Inactive")
      new_worker_types = []
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
  end
end
