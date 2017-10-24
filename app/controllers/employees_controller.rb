class EmployeesController < ApplicationController
  load_and_authorize_resource
  helper EmployeeHelper

  before_action :set_employee, only: :show

  def index
    if current_user.role_names.count == 1 && current_user.role_names.include?("Manager")
      @employees = current_user.employee.direct_reports
    else
      @employees = Employee.all.includes([:manager, :emp_transactions, :profiles => [:job_title, :location, :worker_type]])
    end
    @employees = @employees.page(params[:page])

    if search_params[:search]
      @employees = @employees.search(search_params[:search]).order("last_name ASC")
    end
  end

  def show
    @email = Email.new
    activity = []
    @employee.emp_transactions.map { |e| activity << e }
    @employee.emp_deltas.map { |e| activity << e }
    @activities = activity.sort_by!(&:created_at).reverse!
  end

  def direct_reports
    @employee = Employee.find(params[:employee_id])
    @employees = @employee.direct_reports
  end

  def autocomplete_name
    term = params[:term]
    if term && !term.empty?
      @employees = Employee.search(params[:term])
    else
      term = {}
    end
    render :json => json_for_autocomplete(@employees, :fn , [:employee_id])
  end

  def autocomplete_email
    term = params[:term]
    if term && !term.empty?
      @employees = Employee.search_email(params[:term])
    else
      term = {}
    end
    render :json => json_for_autocomplete(@employees, :email , [:first_name, :last_name, :hire_date])
  end

  private

  def set_employee
    @employee = Employee.includes(:profiles => [:job_title, :department, :location, :worker_type]).find(params[:id])
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
      :home_address_1,
      :home_address_2,
      :home_city,
      :home_state,
      :home_zip,
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
