class EmployeesController < ApplicationController
  load_and_authorize_resource

  before_action :set_employee, only: :show

  def index
    if current_user.role_names.count == 1 && current_user.role_names.include?("Manager")
      @employees = Employee.direct_reports_of(current_user.employee_id)
    else
      @employees = Employee.all.includes(:profiles => [:job_title, :department, :location, :worker_type])
    end

    if search_params[:search]
      @employees = @employees.search(search_params[:search]).order("last_name ASC")
    end
  end

  def show
    @email = Email.new
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
