require 'csv'
require 'net/sftp'

class BetterworksService

  def generate_csv
    get_employees

  end

  # include regular full-time and regular part-time employees only
  # employees with hire date less than today
  # do not include any employee with a termination date < July 14, 2017

  def get_employees
    active_emps = Employee.where("hire_date <= ?", Date.today)
    Employee.joins(:worker_type).where(:worker_types => {:kind => "Regular"})
  end

end
