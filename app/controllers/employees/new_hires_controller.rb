class Employees::NewHiresController < ApplicationController
  helper EmployeeHelper
  authorize_resource class: false

  def index
    @filterrific = initialize_filterrific(
      Profile.includes(:employee).where("start_date >= ?", Date.today),
      params[:filterrific],
      select_options: {
        sorted_by: Profile.options_for_sort,
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
end
