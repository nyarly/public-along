class Employees::NewHiresController < ApplicationController
  helper EmployeeHelper
  helper_method :sort_column, :sort_direction

  def index
    @filterrific = initialize_filterrific(
      Profile.includes(:employee).where("start_date >= ?", Date.today).order("#{sort_column} #{sort_direction}"),
      params[:filterrific],
      select_options: {
        with_location_id: Location.options_for_select,
        with_department_id: Department.options_for_select
      },
      persistence_id: 'shared_key',
      default_filter_params: {},
      available_filters: [:sorted_by, :with_location_id, :with_department_id],
    ) or return

    @new_hires = @filterrific.find.page(params[:page])

    respond_to do |format|
      format.html
      format.js
    end
  end

  private

  def sortable_tables
    ['employees', 'locations', 'departments', 'profiles']
  end

  def sortable_columns
    ['last_name', 'name', 'start_date']
  end

  def table_name
    sortable_tables.include?(params[:table_name]) ? params[:table_name] : nil
  end

  def column
    sortable_columns.include?(params[:column]) ? params[:column] : nil
  end

  def valid_params?
    table_name.present? &&
    column.present? &&
    (table_name.classify.constantize.column_names.include? column)
  end

  def sort_direction
    return 'asc' if params[:direction].blank?
    valid_sort_direction? ? params[:direction] : 'desc'
  end

  def valid_sort_direction?
    %w[asc desc].include?(params[:direction])
  end

  def sort_column
    valid_params? ? model_column : 'employees.last_name'
  end

  def model_column
    table_name + '.' + column
  end

  def filtering_params(params)
    params.slice(:location, :department)
  end
end
