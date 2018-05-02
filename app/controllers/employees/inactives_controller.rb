class Employees::InactivesController < ApplicationController
  def index
    @inactives = Employee.where(status: 'inactive')
    @inactives = @inactives.page(params[:page])
  end
end
