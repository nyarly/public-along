class EmployeesController < ApplicationController
  load_and_authorize_resource
  helper EmployeeHelper, AddressHelper

  before_action :set_employee, only: [:show, :direct_reports]

  def index
    if current_user.manager_role_only?
      @employees = current_user.employee.direct_reports
                               .includes([:manager, :emp_transactions, :profiles])
                               .order(:last_name)
    else
      @employees = Employee.all.includes([:manager, :emp_transactions, :profiles])
                           .order(:last_name)
    end

    filter_and_search
  end

  def show
    if current_user.manager_role_only? && !ManagementTreeQuery.new(@employee).up.include?(current_user.employee_id)
      @employee = nil
      redirect_to :back, alert: 'You are not authorized to view this page.'
    end
    if @employee.present?
      @email = Email.new
      @activities = ActivityFeedQuery.new(@employee).all
    end
  end

  def direct_reports
    @employees = @employee.direct_reports.includes([:manager, :emp_transactions, :profiles])
                          .order(:last_name)

    filter_and_search
  end

  def autocomplete_name
    @employees = @employees.search(params[:term])
    render json: json_for_autocomplete(@employees, :fn, [:employee_id])
  end

  def autocomplete_email
    @employees = Employee.search_email(params[:term])
    render json: json_for_autocomplete(@employees, :email, [:first_name, :last_name, :hire_date])
  end

  private

  def filter_and_search
    @filterrific = initialize_filterrific(
      @employees,
      params[:filterrific],
      select_options: {
        with_status: Employee.status_options,
        with_location_id: Location.options_for_select,
        with_department_id: Department.options_for_select,
        with_worker_type_id: WorkerType.options_for_select
      },
      persistence_id: 'shared_key',
      default_filter_params: {},
      available_filters: [
        :search_query,
        :with_status,
        :with_location_id,
        :with_department_id,
        :with_worker_type_id,
        :sorted_by],
    ) or return

    @employees = @filterrific.find.page(params[:page])

    respond_to do |format|
      format.html
      format.js
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
