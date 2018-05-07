class Employees::InactivesController < ApplicationController
  authorize_resource class: false

  def index
    @filterrific = initialize_filterrific(
      Employee.inactives,
      params[:filterrific],
      select_options: {
        sorted_by: Employee.options_for_inactive_sort
      },
      persistence_id: 'shared_key',
      default_filter_params: {},
      available_filters: [:sorted_by]
    ) or return

    @inactives = @filterrific.find.page(params[:page])

    respond_to do |format|
      format.html
      format.js
    end
  end
end
