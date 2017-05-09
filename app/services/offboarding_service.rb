class OffboardingService
  APPLICATIONS = ["Google Apps", "Office 365", "OTA", "CHARM EU", "CHARM JP", "CHARM NA", "ROMS"]

  def initialize(employees)
    processed_offboards = []

    employees.each do |employee|
      offboard_access_levels = []

      employee.active_security_profiles.each do |sp|
        sp.access_levels.each do |al|

          application = Application.find(al.application_id)
          if APPLICATIONS.include? application.name
            offboard_access_levels << al
          end
        end
      end
      processed_offboards << process(offboard_access_levels, employee)
    end

    processed_offboards
  end

  private

  def process(offboard_access_levels, employee)
    offboarding_info = offboarding_info(employee)

    offboard_access_levels.each do |access_level|
      app_transaction = emp_transaction.app_transactions.build(
        application_id: access_level.id,
        emp_transaction_id: emp_transaction.id,
        status: "Pending"
      )

      if access_level.name == "Google Apps"
        # call google app service with app_transaction & info
      elsif access_level.name == "Office 365"
        # call office 365 service with app_transaction & info
      elsif access_level.name.include? == "CHARM"
        # call charm service with app_transaction
      elsif access_level.name == "ROMS"
        # call ROMS service with app_transaction
      elsif access_level.name == "OTA"
        # call OTA service with app_transaction
      end

      app_transaction.save!
    end unless access_level.blank?

    send_notification(emp_transaction, employee)
    emp_transaction
  end

  def offboarding_info(employee)
    employee.offboarding_infos.last || default_offboarding_info(employee)
  end

  def default_offboarding_info(employee)

    emp_transaction = employee.emp_transactions.build(
      kind: "Offboarding",
      user_id: SECRETS.default_mezzo_user_id || 1,
      notes: "Automatically generated by Mezzo"
    )

    offboarding_info = emp_transaction.offboarding_infos.build(
      employee_id: employee.id,
      archive_data: nil,
      replacement_hired: nil,
      forward_email_id: employee.manager_id,
      reassign_salesforce_id: employee.manager_id,
      transfer_google_docs_id: employee.manager_id,
      emp_transaction_id: emp_transaction.id
    )

    emp_transaction.save!
    offboarding_info.save!
    offboarding_info
  end

  def send_notification(emp_transaction, employee)
    TechTableMailer.offboard_status(emp_transaction, employee).deliver_now
  end

end
