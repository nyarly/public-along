require 'csv'
require 'net/sftp'

class BetterworksService


  # include employees with hire date less or equal to today
  # include employees with termination date >= July 14, 2017
  # include regular full-time and regular part-time employees only
  def betterworks_users
    active_emps = Employee.where("hire_date <= ? AND termination_date IS NULL", Date.today)
    regular_active_emps = active_emps.joins(:worker_type).where(:worker_types => {:kind => "Regular"}).to_a
    regular_active_emps
  end

  # betterworks recommends the following columns:
  # "email", "first_name", "last_name", "department_name", "title", "manager_email", "deactivation_date"
  # deactivation_date should be blank for current employees
  def generate_employee_csv
    dirname = "tmp/betterworks"

    # delete old file
    Dir["tmp/betterworks/*"].each do |f|
      File.delete(f)
    end

    unless File.directory?(dirnmae)
      FileUtils.mkdir_p(dirname)
    end

    headers = [
      "email",
      "first_name",
      "last_name",
      "department_name",
      "title",
      "manager_email",
      "deactivation_date"
    ]

    filename = "tmp/betterworks/OT_Betterworks_Users" + DateTime.now.strftime('%Y%m%d') + ".csv"

    CSV.open(filename, "w+", {headers: true, col_sep: "|"}) do |csv|
      csv << headers

      betterworks_users.each do |u|
        manager_email = u.manager ? u.manager.email : ""

        csv << [
          u.email,
          u.first_name,
          u.last_name,
          u.department.name,
          u.job_title.name,
          manager_email,
          u.termination_date
        ]
      end
    end
  end

  def sftp_drop
    uri = URI.parse("sftp://#{SECRETS.betterworks_host}")
    Net::SFTP.start(uri.host, SECRETS.betterworks_user, password: SECRETS.betterworks_pw ) do |sftp|
      # sftp.upload!("tmp/saba/OT_Betterworks_Users.csv", "/")
      sftp.dir.foreach("/incoming") do |t|
        puts t.inspect
      end
    end
  end

end
