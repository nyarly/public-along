class OffboardingService
  APPLICATIONS = ["Google Apps", "Office 365", "OTA", "CHARM EU", "CHARM JP", "CHARM NA", "ROMS"]

  def initialize(employees)
    processed_offboards = []

    employees.each do |employee|
      offboard_accounts = []

      employee.active_security_profiles.each do |sp|
        sp.access_levels.each do |a|

          application = Application.find(a.application_id)
          if APPLICATIONS.include? application.name
            offboard_accounts << application
          end
        end
      end
      processed_offboards << process(offboard_accounts, employee)
    end

    processed_offboards
  end

  private

  def process(accounts, employee)
    offboarding_info = offboarding_info(employee)
    emp_transaction = offboarding_info.emp_transaction

    accounts.each do |account|
      app_transaction = emp_transaction.app_transactions.build(
        application_id: account.id,
        emp_transaction_id: emp_transaction.id,
        status: "Pending"
      )

      if account.name == "Google Apps"
        # call google app service with app_transaction & info
      elsif account.name == "Office 365"
        # call office 365 service with app_transaction & info
      elsif account.name.include? == "CHARM"
        # call charm service with app_transaction
      elsif account.name == "ROMS"
        # call ROMS service with app_transaction
      elsif account.name == "OTA"
        # call OTA service with app_transaction
      end

      app_transaction.save!
    end unless accounts.blank?

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
