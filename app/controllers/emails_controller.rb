class EmailsController < ApplicationController
  load_and_authorize_resource

  def create
    @email = Email.new(email_params)

    if @email.valid?
      send_email
      render :nothing => true
    else
      flash.now[:notice] = "Unable to send email."
    end
  end

  def send_email
    @employee = Employee.find(@email.employee_id)
    @manager = Employee.find_by(employee_id: @employee.manager_id)
    ManagerMailer.permissions(@manager, @employee, @email.email_kind).deliver_now
  end

  private

  def email_params
    params.require(:email).permit(:employee_id, :email_kind)
  end

end