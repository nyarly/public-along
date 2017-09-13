require 'csv'
require 'net/sftp'

class BetterworksService


  # include employees with hire date less or equal to today (don't include pending workers)
  # include employees with termination date >= July 24, 2017
  # include regular full-time and regular part-time employees only
  def betterworks_users
    # beginning from launch of service
    launch_date = Date.new(2017, 7, 24)

    user_group = Employee.where("termination_date >= ? OR termination_date IS NULL", launch_date)
    current_users = user_group.where("hire_date <= ?", Date.today)
    current_users.joins(:profiles).merge(Profile.regular_worker_type).to_a
  end

  # betterworks recommends the following columns:
  # "email", "first_name", "last_name", "department_name", "title", "manager_email", "deactivation_date"
  # deactivation_date should be blank for current employees
  def generate_employee_csv
    dirname = "tmp/betterworks"
    file_name = "tmp/betterworks/OT_Betterworks_Users_" + DateTime.now.strftime('%Y%m%d') + ".csv"

    # delete old file
    Dir["tmp/betterworks/*"].each do |f|
      File.delete(f)
    end

    unless File.directory?(dirname)
      FileUtils.mkdir_p(dirname)
    end

    headers = [
      "email",
      "employee_id",
      "first_name",
      "last_name",
      "department_name",
      "title",
      "location",
      "deactivation_date",
      "on_leave",
      "manager_id",
      "manager_email"
    ]

    CSV.open(file_name, "w+", {headers: true, col_sep: ","}) do |csv|
      csv << headers

      betterworks_users.each do |u|
        manager_email = u.manager_id.present? ? u.manager.email : ""
        manager_id = u.manager_id.present? ? u.manager_id : ""
        on_leave = u.status == "Inactive"

        csv << [
          u.email,
          u.employee_id,
          u.first_name,
          u.last_name,
          u.department.name,
          u.job_title.name,
          u.location.name,
          deactivation_date(u),
          on_leave,
          manager_id,
          manager_email
        ]
      end
    end
  end

  def sftp_drop
    uri = URI.parse("sftp://#{SECRETS.betterworks_host}")

    Net::SFTP.start(uri.host, SECRETS.betterworks_user, password: SECRETS.betterworks_pw ) do |sftp|
      sftp.upload!("tmp/betterworks", "/incoming")
    end
  end

  def deactivation_date(emp)
    if emp.termination_date.present? && emp.termination_date <= Date.today
      emp.termination_date.strftime("%m/%d/%Y")
    end
  end

end
