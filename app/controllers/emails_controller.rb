class EmailsController < ApplicationController
  load_and_authorize_resource
  rescue_from ActionController::RedirectBackError, with: :redirect_to_default

  def create
    @email = Email.new(email_params)

    if @email.valid?
      send_now
      redirect_to :back, notice: "Email sent successfully."
    else
      redirect_to :back, notice: "Unable to send email."
    end
  end

  def send_now
    @employee = Employee.find(@email.employee_id)
    @manager = Employee.find_by(employee_id: @employee.manager_id)
    ManagerMailer.permissions(@manager, @employee, @email.email_option).deliver_now
  end

  private

  def redirect_to_default
    redirect_to employees_path
  end

  def email_params
    params.require(:email).permit(:employee_id, :email_option)
  end

end
