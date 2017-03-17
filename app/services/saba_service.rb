# For generating pipe delimited csv files to send to SABA

require 'csv'
require 'net/sftp'

class SabaService

  def generate_csvs
    # delete old files
    Dir["tmp/saba/*"].each do |f|
      File.delete(f)
    end

    dirname = 'tmp/saba'
    unless File.directory?(dirname)
      FileUtils.mkdir_p(dirname)
    end

    create_org_csv
    create_loc_csv
    create_job_type_csv
    create_person_csv
  end

  def sftp_drop
    uri = URI.parse("sftp://#{SECRETS.saba_sftp_host}")
    Net::SFTP.start(uri.host, SECRETS.saba_sftp_user, password: SECRETS.saba_sftp_pass, port: SECRETS.saba_sftp_port ) { |f|
      f.upload!("tmp/saba", SECRETS.saba_sftp_path)
    }
  end

  def create_org_csv
    headers = [
      "NAME",
      "SPLIT",
      "PARENT_ORG",
      "NAME2",
      "DEFAULT_CURRENCY"
    ]

    filename = "tmp/saba/organization_" + DateTime.now.strftime('%Y%m%d') + ".csv"
    CSV.open(filename, "w+", {headers: true, col_sep: "|"}) do |csv|
      csv << headers

      Department.find_each do |dept|
        if dept.parent_org_id.present?
          parent = ParentOrg.find(dept.parent_org_id).code
        else
          parent = "OPENTABLE"
        end

        csv << [
          dept.code,
          "OpenTable",
          parent,
          dept.name,
          "USD"
        ]
      end

      ParentOrg.find_each do |po|
        csv << [
          po.code,
          "OpenTable",
          "OPENTABLE",
          po.name,
          "USD"
        ]
      end
    end
  end

  def create_loc_csv
    headers = [
      "LOC_NO",
      "DOMAIN",
      "LOC_NAME",
      "ENABLED",
      "TIMEZONE",
      "PHONE1",
      "ADDR1",
      "ADDR2",
      "CITY",
      "STATE",
      "ZIP",
      "COUNTRY"
    ]
    filename = "tmp/saba/location_" + DateTime.now.strftime('%Y%m%d') + ".csv"
    CSV.open(filename, "w+", {headers: true, col_sep: "|"}) do |csv|
      csv << headers

      Location.find_each do |loc|
        enabled = (loc.status == "Active" ? "TRUE" : "FALSE")

        csv << [
          loc.code,
          "OpenTable",
          loc.name,
          enabled,
          loc.timezone,
          nil,
          nil,
          nil,
          nil,
          nil,
          nil,
          nil
        ]
      end
    end
  end

  def create_job_type_csv
    headers = [
      "NAME",
      "DOMAIN",
      "JOB_CODE",
      "JOB_FAMILY",
      "STATUS",
      "LOCALE"
    ]
    filename = "tmp/saba/jobtype_" + DateTime.now.strftime('%Y%m%d') + ".csv"
    CSV.open(filename, "w+", {headers: true, col_sep: "|"}) do |csv|
      csv << headers

      JobTitle.find_each do |jt|
        status = (jt.status == "Active" ? 100 : 200)

        csv << [
          jt.code + " - " + jt.name,
          "OpenTable",
          jt.code,
          "All Jobs",
          status,
          "English"
        ]
      end
    end
  end

  def create_person_csv
    headers = [
      "PERSON_NO",
      "STATUS",
      "MANAGER",
      "PERSON_TYPE",
      "HIRED_ON",
      "TERMINATED_ON",
      "JOB_TYPE",
      "SECURITY_DOMAIN",
      "RATE",
      "LOCATION",
      "GENDER",
      "HOME_DOMAIN",
      "LOCALE",
      "TIMEZONE",
      "COMPANY",
      "FNAME",
      "LNAME",
      "EMAIL",
      "USERNAME",
      "JOB_TITLE",
      "HOME_COMPANY",
      "CUSTOM0"
    ]
    filename = "tmp/saba/person_" + DateTime.now.strftime('%Y%m%d') + ".csv"
    CSV.open(filename, "w+", {headers: true, col_sep: "|"}) do |csv|
      csv << headers

      Employee.find_each do |e|
        if e.status == "Pending"
          status = "Active"
        elsif e.status == "Inactive"
          status = "Leave"
        else
          status = e.status
        end

        domain = e.worker_type.kind == "Contractor" ? "OpenTable_Contractor" : "OpenTable"
        email = SECRETS.saba_sftp_path.include?("uat") ? nil : e.email
        csv << [
          e.employee_id,
          status,
          e.manager_id,
          e.worker_type.try(:name),
          e.hire_date.strftime("%Y-%m-%d"),
          e.termination_date.try(:strftime, "%Y-%m-%d"),
          e.job_title.try(:code),
          domain,
          0,
          e.location.try(:code),
          3,
          domain,
          "English",
          nil,
          e.department.try(:code),
          e.first_name,
          e.last_name,
          email,
          e.email,
          e.job_title.try(:name),
          e.department.try(:code),
          e.company
        ]
      end
    end
  end
end
