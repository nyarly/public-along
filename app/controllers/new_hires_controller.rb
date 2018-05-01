class NewHiresController < ApplicationController
  helper EmployeeHelper
  helper_method :sort_column, :sort_direction

  def index
    @new_hires = Profile.includes([:employee, :department, :location])
                        .where("start_date >= ?", Date.today)
                        .order("#{sort_column} #{sort_direction}")
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
    (table_name.classify.column_names.include? column)
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
end
