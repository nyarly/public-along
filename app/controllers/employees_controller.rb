class EmployeesController < ApplicationController
  load_and_authorize_resource

  before_action :set_employee, only: [:show, :edit, :update]

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
    @email = Email.new(employee_id: @employee.id)
  end

  def new
    @employee = Employee.new
  end

  def edit
  end

  def create
    @employee = Employee.new(employee_params)

    if @employee.save
      ads = ActiveDirectoryService.new
      ads.create_disabled_accounts([@employee])

      if ads.errors.present?
        redirect_to edit_employee_path(@employee), alert: "#{ads.errors[:active_directory]}"
      else
        redirect_to employee_path(@employee), notice: "#{@employee.cn}'s record was successfully created."
      end
    else
      render 'new'
    end
  end

  def update
    @employee.assign_attributes(employee_params)

    set_email_kind
    build_emp_delta

    if @employee.update(employee_params)
      @emp_delta.save

      send_manager_emails

      ads = ActiveDirectoryService.new

      if @employee.ad_updated_at == nil
        ads.create_disabled_accounts([@employee])
      else
        ads.update([@employee])
      end

      if ads.errors.present?
        redirect_to edit_employee_path(@employee), alert: "#{ads.errors[:active_directory]}"
      else
        redirect_to employee_path(@employee), notice: "#{@employee.cn}'s record was successfully updated."
      end
    else
      render :edit
    end
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

  def set_email_kind
    if @employee.changed? && @employee.valid?
      if @employee.hire_date_changed? && @employee.termination_date_changed?
        @email_kind = "Onboarding"
      elsif @employee.termination_date_changed? && !@employee.termination_date.blank?
        @email_kind = "Offboarding"
      elsif @employee.manager_id_changed? || @employee.business_title_changed?
        @email_kind = "Security Access"
      end
    end
  end

  def build_emp_delta
    before = @employee.changed_attributes
    after = Hash[@employee.changes.map { |k,v| [k, v[1]] }]
    @emp_delta = EmpDelta.new(
      employee_id: @employee.id,
      before: before,
      after: after
    )
  end

  def send_manager_emails
    unless @email_kind.blank?
      if (@email_kind == "Offboarding") && (Time.now < 5.business_days.before(@employee.termination_date))
        EmployeeWorker.perform_at(5.business_days.before(@employee.termination_date), "Offboarding", @employee.id)
      else
        EmployeeWorker.perform_async(@email_kind, @employee.id)
      end
    end
  end

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
      :worker_type_id,
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

  def search_params
    params.permit(:search)
  end
end
