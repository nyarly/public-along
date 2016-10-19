class EmployeesController < ApplicationController
  load_and_authorize_resource

  before_action :set_employee, only: [:show, :edit, :update]

  def index
    if current_user.role_names.count == 1 && current_user.role_names.include?("Manager")
      @employees = Employee.direct_reports_of(current_user.employee_id)
    elsif params[:search]
      @employees = Employee.search(params[:search]).order("last_name ASC")
    else
      @employees = Employee.all
    end
  end

  def show
  end

  def new
    @employee = Employee.new
  end

  def edit
  end

  def create
    @employee = Employee.new(employee_params)

    if @employee.save
      EmployeeWorker.perform_async("Onboarding", @employee.id)

      ads = ActiveDirectoryService.new
      ads.create_disabled_accounts([@employee])

      redirect_to employees_path
    else
      render 'new'
    end
  end

  def update
    @employee.assign_attributes(employee_params)

    if @employee.changed? && @employee.valid?
      if @employee.hire_date_changed? && @employee.termination_date_changed?
        EmployeeWorker.perform_async("Onboarding", @employee.id)
      elsif @employee.termination_date_changed? && !@employee.termination_date.blank?
        EmployeeWorker.perform_at(5.business_days.before(@employee.termination_date), "Offboarding", @employee.id) if Time.now < 5.business_days.before(@employee.termination_date)
        EmployeeWorker.perform_async("Offboarding", @employee.id) if Time.now > 5.business_days.before(@employee.termination_date)
      elsif @employee.manager_id_changed? || @employee.business_title_changed?
        EmployeeWorker.perform_async("Security Access", @employee.id)
      end
    end

    if @employee.update(employee_params)
      ads = ActiveDirectoryService.new
      ads.update([@employee])

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
    params.require(:employee).permit(
      :email,
      :first_name,
      :last_name,
      :workday_username,
      :employee_id,
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
      :location_id,
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
