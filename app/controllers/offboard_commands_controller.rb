class OffboardCommandsController < ApplicationController
  load_and_authorize_resource

  def generate
    if params[:employee_id]
      @offboard_command = OffboardCommand.new(offboard_params[:employee_id])
    end
  end

  private

  def offboard_params
    params.permit(:employee_id => [])
  end
end
