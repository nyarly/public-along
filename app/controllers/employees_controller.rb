class EmployeesController < ApplicationController
  load_and_authorize_resource

  before_filter :authenticate_user!
  before_action :set_employee, only: [:show, :edit, :update, :destroy]

  def index
    @employees = Employee.all
  end

  def new
    @employee = Employee.new
  end

  def edit
  end

  def create
    @employee = Employee.new(employee_params)
    if @employee.save
      redirect_to employees_path
    else
      render 'new'
    end
  end

  def update
    if @employee.update(employee_params)
      redirect_to employees_path, notice: "#{@employee.cn} was successfully updated."
    else
      render :edit
    end
  end

  private

  def set_employee
    @employee = Employee.find(params[:id])
  end

  def employee_params
    params[:employee][:location_type] = LOCATIONS[params[:employee][:location]] if params[:employee][:location]
    params.require(:employee).permit(
      :email,
      :first_name,
      :last_name,
      :workday_username,
      :employee_id,
      :country,
      :hire_date,
      :contract_end_date,
      :termination_date,
      :job_family_id,
      :job_family,
      :job_profile_id,
      :job_profile,
      :business_title,
      :employee_type,
      :contingent_worker_id,
      :contingent_worker_type,
      :location_type,
      :location,
      :manager_id,
      :department_id,
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
end
