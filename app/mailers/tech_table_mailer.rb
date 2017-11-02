class TechTableMailer < ApplicationMailer
  helper EmployeeHelper
  default to: [Rails.application.secrets.tt_email]

  def alert_email(message)
    @message = message
    mail(subject: "ALERT: Mezzo Error")
  end

  def alert(subject, message, data)
    @subject = subject
    @message = message
    @data = data
    mail(subject: @subject)
  end

  def permissions(emp_transaction)
    @emp_transaction = emp_transaction
    @employee = @emp_transaction.employee
    @manager = User.find(@emp_transaction.user_id)
    mail(subject: "#{@emp_transaction.kind} request for #{@employee.first_name} #{@employee.last_name}")
  end

  def offboard_notice(employee)
    @employee = employee
    @manager = @employee.manager
    mail(subject: "Mezzo Offboarding notice for #{employee.first_name} #{employee.last_name}")
  end

  def offboard_status(employee, deactivations)
    @employee = employee
    @deactivations = deactivations
    mail(to: "ComputerClub@opentable.com", subject: "Mezzo Automated Offboarding Status for #{@employee.first_name} #{@employee.last_name}")
  end

  def offboard_instructions(employee)
    @employee = employee
    @info = TransitionInfo::Offboard.new(employee.employee_id)
    mail(subject: "Mezzo Offboard Instructions for #{@employee.first_name} #{@employee.last_name}")
  end

  def onboard_instructions(emp_transaction, opts={})
    @employee = emp_transaction.employee
    if opts[:link_email]
      @link_email = true
    end
    @info = TransitionInfo::Onboard.new(@employee.employee_id)
    mail(subject: "Mezzo Onboarding Request for #{@employee.first_name} #{@employee.last_name}")
  end
end
