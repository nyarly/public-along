class EmployeeProfile
  include Virtus.model

  extend ActiveModel::Naming
  include ActiveModel::Conversion
  include ActiveModel::Validations

  # attributes for employee model
  attribute :status, String
  attribute :first_name, String
  attribute :last_name, String
  attribute :hire_date, DateTime
  attribute :contract_end_date, DateTime
  attribute :office_phone, String
  attribute :personal_mobile_phone, String
  attribute :home_address_1, String
  attribute :home_address_2, String
  attribute :home_city, String
  attribute :home_state, String
  attribute :home_zip, String

  # attributes for profile model
  attribute :adp_assoc_oid, String
  attribute :adp_employee_id, String
  attribute :company, String
  attribute :department_id, Integer
  attribute :job_title_id, Integer
  attribute :location_id, Integer
  attribute :manager_id, String
  attribute :profile_status, String
  attribute :worker_type_id, Integer
  attribute :profile_status, String

  # is there an employee with the employee id?
    # if yes, get active profile
    #   is the active profile different?
    #     if yes, is there a pending profile that is a match?
    #       if no, make a new profile
    #       if yes, activate that profile
    #     if no, make a new profile
    #       if start date is in future, assign pending
    #         if not, make active
    #           and deactivate active profile

  def do_stuff(hash)
    employee = Employee.find_by_employee_id(hash[:adp_employee_id])

    if employee.present?
      profile = employee.profiles.active
      employee_attrs, profile_attrs = hash.partition{ |k,v| employee.has_attribute?(k) }

      employee.assign_attributes(employee_attrs.to_h)

      profile.assign_attributes(profile_attrs.to_h)

      if profile.changed?
        puts "profile changes"
        puts profile.changed_attributes
        old_profile = employee.profiles.active
        old_profile.profile_status = "Expired"
        old_profile.end_date = Date.today
        if old_profile.save!
          puts "saved?"
        else
          puts "whatever"
        end
        # puts employee.profiles.active.profile_status
        # puts employee.profiles.active.end_date
        employee.profiles.build(profile_attrs.to_h)
        if employee.save!
          puts "saved!"
        else
          puts "didn't save?"
        end
      end
      if employee.changed?
        puts "changes to employee"
        puts employee.changed_attributes
        employee.save!
      end
    else
      puts "???"
    end
  end

  def employee

  end

  def profile

  end

  def save

  end

  def errors
    return @errors ||= {}
  end
end
