class EmployeesController < ApplicationController
  load_and_authorize_resource
  helper EmployeeHelper, AddressHelper

  before_action :set_employee, only: [:show, :direct_reports]

  def index
    if current_user.manager_role_only?
      @employees = current_user.employee.direct_reports.includes([:manager, :emp_transactions])
    else
      @employees = Employee.all.includes([:manager, :emp_transactions])
    end
    @employees = @employees.page(params[:page])
  end

  def show
    if current_user.manager_role_only? && !ManagementTreeQuery.new(@employee).up.include?(current_user.employee_id)
      @employee = nil
      redirect_to :back, :alert => "You are not authorized to view this page."
    end
    unless @employee.blank?
      @email = Email.new
      @activities = ActivityFeedQuery.new(@employee).all
    end
  end

  def direct_reports
    @employees = @employee.direct_reports.includes([:manager,:emp_transactions])
  end

  def autocomplete_name
    @employees = @employees.search(params[:term])
    render :json => json_for_autocomplete(@employees, :fn , [:employee_id])
  end

  def autocomplete_email
    @employees = Employee.search_email(params[:term])
    render :json => json_for_autocomplete(@employees, :email , [:first_name, :last_name, :hire_date])
  end

  private

  def set_employee
    @employee = Employee.find(params[:id])
  end

  def employee_params
    params.require(:employee).permit(
      :email,
      :first_name,
      :last_name,
      :hire_date,
      :contract_end_date,
      :termination_date,
      :personal_mobile_phone,
      :office_phone,
      :image_code,
      :created_at,
      :updated_at,
      :ad_updated_at,
      :leave_start_date,
      :leave_return_date
    )
  end

  def search_params
    params.permit(:search)
  end
end
