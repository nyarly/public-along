class EmployeesController < ApplicationController
  load_and_authorize_resource

  before_action :set_employee, only: :show

  autocomplete :employee, :name, :extra_data => [:employee_id]

  def index
    if current_user.role_names.count == 1 && current_user.role_names.include?("Manager")
      @employees = Employee.direct_reports_of(current_user.employee_id)
    else
      @employees = Employee.all
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

  private

  def set_employee
    @employee = Employee.find(params[:id])
  end

  def employee_params
    params.require(:employee).permit(
      :email,
      :first_name,
      :last_name,
      # :workday_username,
      # :employee_id,
      :hire_date,
      :contract_end_date,
      :termination_date,
      # :job_family_id,
      # :job_family,
      # :job_profile_id,
      # :job_profile,
      # :job_title_id,
      # :business_title,
      # :employee_type,
      # :worker_type_id,
      # :contingent_worker_id,
      # :contingent_worker_type,
      # :location_id,
      # :manager_id,
      # :department_id,
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
