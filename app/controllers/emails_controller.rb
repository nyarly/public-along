class EmailsController < ApplicationController
  load_and_authorize_resource

  def create
    @email = Email.new(email_params)

    if @email.valid?
      send_now
      redirect_to :back, notice: "Email sent successfully."
    else
      redirect_to :back, notice: "Unable to send email."
    end
  end

  private

  def send_now
    @employee = Employee.find(@email.employee_id)
    @manager = Employee.find_by(employee_id: @employee.manager_id)
    ManagerMailer.permissions(@manager, @employee, @email.email_option).deliver_now
  end

  def email_params
    params.require(:email).permit(:employee_id, :email_option)
  end

end
