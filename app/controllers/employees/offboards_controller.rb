class Employees::OffboardsController < ApplicationController
  helper EmployeeHelper

  def index
    @filterrific = initialize_filterrific(
      Employee.offboards,
      params[:filterrific],
      select_options: {
        sorted_by: Employee.options_for_sorted_by
      },
      persistence_id: 'shared_key',
      default_filter_params: {},
      available_filters: [:sorted_by]
    ) or return

    @offboards = @filterrific.find.page(params[:page])

    respond_to do |format|
      format.html
      format.js
    end
  end
end
